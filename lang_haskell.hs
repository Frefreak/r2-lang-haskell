{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE Strict #-}

module Plugin where

import Language.Haskell.Ghcid
import Control.Concurrent.MVar
import Control.Monad
import System.IO
import System.IO.Unsafe (unsafePerformIO)
import Foreign.Ptr
import Control.Concurrent

foreign export ccall "init_ghci" initGhci :: IO ()
foreign export ccall "fini_ghci" finiGhci :: IO ()
foreign export ccall "prompt" prompt :: Ptr RCore -> IO ()

data RCore

{-# NOINLINE ghciInstance #-}
ghciInstance :: MVar Ghci
ghciInstance = unsafePerformIO newEmptyMVar

genericCallback :: Stream -> String -> IO ()
genericCallback _ = putStrLn

initGhci :: IO ()
initGhci = do
    let echooff _ _ = return ()
    void $ forkIO $ do
        (ghci, _) <- startGhci "stack exec -- ghci" Nothing echooff
        putMVar ghciInstance ghci
        putStrLn "initialized"

finiGhci :: IO ()
finiGhci = readMVar ghciInstance >>= stopGhci >> putStrLn "exited"

recursiveGet :: MVar a -> IO a
recursiveGet mvar = do
    v <- tryReadMVar mvar
    case v of
        Just v' -> return v'
        Nothing -> putStrLn "." >> threadDelay 500000 >> recursiveGet mvar

prompt :: Ptr RCore -> IO ()
prompt _ = do
    ghci <- recursiveGet ghciInstance
    outBuf <- hGetBuffering stdout
    errBuf <- hGetBuffering stderr
    hSetBuffering stdout NoBuffering
    hSetBuffering stderr NoBuffering
    promptLoop ghci
    hSetBuffering stdout outBuf
    hSetBuffering stderr errBuf

promptLoop :: Ghci -> IO ()
promptLoop ghci = do
    b <- isEOF
    unless b $ do
        putStr "\ESC[32;1mλ> \ESC[0m"
        {- hFlush stdout -}
        {- hFlush stderr -}
        l <- getLine
        execStream ghci l genericCallback
        promptLoop ghci
