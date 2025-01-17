{-# LANGUAGE AllowAmbiguousTypes  #-}
{-# LANGUAGE ConstraintKinds      #-}
{-# LANGUAGE TemplateHaskell      #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE UndecidableInstances #-}

{-# OPTIONS_HADDOCK not-home #-}

module Polysemy.Internal.CustomErrors
  ( WhenStuck
  , FirstOrder
  , type (<>)
  , type (%)
  ) where

import Data.Kind
import Fcf
import GHC.TypeLits (Symbol)
import Polysemy.Internal.Kind
import Polysemy.Internal.CustomErrors.Redefined
import Type.Errors hiding (IfStuck, WhenStuck, UnlessStuck)


-- These are taken from type-errors-pretty because it's not in stackage for 9.0.1
-- See https://github.com/polysemy-research/polysemy/issues/401
type family ToErrorMessage (t :: k) :: ErrorMessage where
    ToErrorMessage (t :: Symbol) = 'Text t
    ToErrorMessage (t :: ErrorMessage) = t
    ToErrorMessage t = 'ShowType t

infixl 5 <>
type family (<>) (l :: k1) (r :: k2) :: ErrorMessage where
    l <> r = ToErrorMessage l ':<>: ToErrorMessage r

infixr 4 %
type family (%) (t :: k1) (b :: k2) :: ErrorMessage where
    t % b = ToErrorMessage t ':$$: ToErrorMessage b

data FirstOrderErrorFcf :: k -> Symbol -> Exp Constraint
type instance Eval (FirstOrderErrorFcf e fn) = $(te[t|
    UnlessPhantom
        (e PHANTOM)
        ( "'" <> e <> "' is higher-order, but '" <> fn <> "' can help only"
        % "with first-order effects."
        % "Fix:"
        % "  use '" <> fn <> "H' instead."
        ) |])

------------------------------------------------------------------------------
-- | This constraint gives helpful error messages if you attempt to use a
-- first-order combinator with a higher-order type.
type FirstOrder (e :: Effect) fn = UnlessStuck e (FirstOrderErrorFcf e fn)


data DoError :: ErrorMessage -> Exp k
type instance Eval (DoError a) = TypeError a
