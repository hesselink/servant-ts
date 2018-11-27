{-# LANGUAGE DeriveAnyClass #-}
module TSFunctions where

import           Control.Lens
import Data.Text.Strict.Lens
import Data.Char (toUpper)
import           Data.Maybe      (fromMaybe)
import           Data.Monoid     ((<>))
import           Data.Proxy
import           Data.Text       (Text)
import qualified Data.Text       as T
import           Debug.Trace
import           GHC.Generics
import           Servant.API
import           Servant.Foreign
import           Typescript

data TSFunctionConfig =
  TSFunctionConfig
    {_tsFuncName   :: Text
    ,_tsArgs       :: [TSArg]
    ,_tsReturnType :: Text
    ,_body         :: Text
    }

data TSTypedVar = TSTypedVar {varName :: Text, varType :: Text}

printTSTypedVar (TSTypedVar name' type') = name' <> " : " <> type'

newtype TSArg = TSArg {getTypedVar :: TSTypedVar}

printArgs :: [TSArg] -> Text
printArgs tsArgs' =
  T.intercalate "," $ (printTSTypedVar . getTypedVar) <$> tsArgs'

printTSFunction :: TSFunctionConfig -> Text
printTSFunction (TSFunctionConfig tsFuncName' tsArgs' tsReturnType' body') =
  "function "
    <> tsFuncName'
    <> "("
    <> printArgs tsArgs'
    <> "): "
    <> tsReturnType'
    <> " {\n"
    <> body'
    <> "}\n"

reqToTSFunction
  :: (IsForeignType (TSIntermediate flavor))
  => Req (TSIntermediate flavor)
  -> TSFunctionConfig
reqToTSFunction req = TSFunctionConfig
  { _tsFuncName   = reqToTSFunctionName req
  , _tsArgs       = fmap (reqArgToTSArg . _headerArg) $ req ^. reqHeaders
  , _tsReturnType = fromMaybe "void"
    $ fmap (refName . toForeignType) (req ^. reqReturnType)
  , _body         = ""
  }

reqArgToTSArg
  :: (IsForeignType (TSIntermediate flavor))
  => Arg (TSIntermediate flavor)
  -> TSArg
reqArgToTSArg (Arg argName' argType') = TSArg $ TSTypedVar
  { varName = unPathSegment argName'
  , varType = refName . toForeignType $ argType'
  }

reqToTSFunctionName
  :: (IsForeignType (TSIntermediate flavor))
  => Req (TSIntermediate flavor)
  -> Text
reqToTSFunctionName req = combineWords $ unFunctionName $ req ^. reqFuncName
 where
  combineWords :: [Text] -> Text
  combineWords []       = ""
  combineWords [x     ] = x
  combineWords (x : xs) = x <> combineWords (fmap capFirstLetter xs)

  capFirstLetter :: Text -> Text
  capFirstLetter = (T.pack . over _head toUpper . T.unpack)
