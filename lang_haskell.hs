{-# LANGUAGE ForeignFunctionInterface #-}

module Plugin where

import Control.Concurrent.MVar
import Control.Concurrent
import Control.Monad
import System.IO
import System.IO.Unsafe (unsafePerformIO)
import Foreign.Ptr
import Foreign.C.String
import Control.Monad.IO.Class

import GHC
import GHC.Paths
import DynFlags

foreign export ccall "hs_prompt" prompt :: Ptr RCore -> IO ()

data RCore

{-# NOINLINE ghcSession #-}
ghcSession :: MVar HscEnv
ghcSession = unsafePerformIO newEmptyMVar

prompt :: Ptr RCore -> IO ()
prompt ptr = do
    sess <- tryReadMVar ghcSession
    -- lowest level code I ever wrote in Haskell
    let addr = fromIntegral (ptrToIntPtr ptr)
    newSess <- case sess of
                Nothing -> putStrLn "realinit" >> realInit >>= repl addr
                Just sess' -> putStrLn "normal init" >> repl addr sess'
    _ <- tryTakeMVar ghcSession
    putMVar ghcSession newSess
    return ()

realInit :: IO HscEnv
realInit =
    defaultErrorHandler defaultFatalMessager defaultFlushOut $
        runGhc (Just libdir) $ do
            dflags <- getSessionDynFlags
            _ <- setSessionDynFlags dflags
                    { hscTarget = HscInterpreted, ghcLink = LinkInMemory }
            target <- guessTarget "R2.hs" Nothing
            addTarget target
            _ <- load LoadAllTargets
            setContext $ map (IIDecl . simpleImportDecl . mkModuleName)
                ["Prelude", "R2"]
            getSession

repl :: Int -> HscEnv -> IO HscEnv
repl addr sess =
    defaultErrorHandler defaultFatalMessager defaultFlushOut $
        runGhc (Just libdir) $ do
            setSession sess
            _ <- execStmt ("dangerousInit " ++ show addr) execOptions
            repl'
            getSession

repl' :: GhcMonad m => m ()
repl' = do
    l <- liftIO getLine
    execStmt l execOptions
    l <- liftIO getLine
    execStmt l execOptions
    l <- liftIO getLine
    execStmt l execOptions
    return ()
