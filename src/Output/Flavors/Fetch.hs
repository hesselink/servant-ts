module Output.RequestFlavors.Fetch where

import Output.TSFunctions
import           TypeOutput.Flavorsscript
import           Servant.Foreign
import Data.Text
import Control.Lens

reqToTSFunction
  :: (IsForeignType (TSIntermediate flavor))
  => Req (TSIntermediate flavor)
  -> TSFunctionConfig
reqToTSFunction req = TSFunctionConfig
  { _tsFuncName   = reqToTSFunctionName req
  , _tsArgs       = reqToTSFunctionArgs req
  , _tsReturnType = maybe "void"
                          (asPromise . refName . toForeignType)
                          (req ^. reqReturnType)
  , _body         = mkBody req
  }

mkBody
  :: (IsForeignType (TSIntermediate flavor))
  => Req (TSIntermediate flavor)
  -> TSFunctionBody
mkBody req = TSFunctionBody ["return fetch(\\`" <> withDefaultUrlFunc $ getReqUrl req <> "\\`)"]
