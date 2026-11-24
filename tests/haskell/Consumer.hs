{-# LANGUAGE ForeignFunctionInterface #-}

-- | GHC consumer of the published C ABI.
--
-- This is the contract from the other side: a plain GHC program that links the
-- release archive at build time and calls the three public entry points through
-- @foreign import ccall@. It catches the class of bug that raw Lean exports
-- invite (a nullary @[export] is a data symbol, not a function) and pins the
-- fixtures that Graphos parity depends on.
--
-- Usage: @consumer <expected-packed-semver>@ (0.2.1 -> 201).
module Main (main) where

import Data.Word (Word8, Word32, Word64)
import System.Environment (getArgs)
import System.Exit (exitFailure)

foreign import ccall unsafe "graphos_lean_critique_abi_version"
  c_abiVersion :: IO Word32

foreign import ccall unsafe "graphos_lean_critique_semver"
  c_semver :: IO Word32

foreign import ccall unsafe "graphos_surprise_score"
  c_surpriseScore :: Word8 -> Word8 -> Word8 -> Word8 -> Word64

-- | Pinned ABI v0 fixtures, identical to 'GraphosLeanCritique.Checks' and
-- @tests/c/abi_smoke.c@.
fixtures :: [(Word8, Word8, Word8, Word8, Word64)]
fixtures =
  [ (0, 1, 1, 0, 6)
  , (0, 1, 1, 1, 10)
  , (9, 0, 0, 0, 1)
  ]

main :: IO ()
main = do
  args <- getArgs
  let expectedSemver = case args of
        (s : _) -> read s
        [] -> 201 -- 0.2.1; CI passes the value derived from VERSION
  abi <- c_abiVersion
  semver <- c_semver
  putStrLn $ "abi version = " ++ show abi
  putStrLn $ "packed semver = " ++ show semver
  results <- mapM checkFixture fixtures
  let versionOk = abi == 0 && semver == expectedSemver
  if and results && versionOk
    then putStrLn "GHC consumer: fixtures and version surface OK"
    else do
      putStrLn "GHC consumer: FAILED"
      exitFailure
  where
    checkFixture (confX10, crossFiletype, crossComm, inferred, expected) = do
      let got = c_surpriseScore confX10 crossFiletype crossComm inferred
      putStrLn $
        "score (" ++ show confX10 ++ "," ++ show crossFiletype ++ ","
          ++ show crossComm ++ "," ++ show inferred ++ ") = " ++ show got
      pure (got == expected)
