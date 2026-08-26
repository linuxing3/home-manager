{-# LANGUAGE FlexibleContexts #-}

import qualified Data.Map as M
import System.Exit (exitSuccess)
import XMonad
import XMonad.Actions.CopyWindow (copy)
import XMonad.Actions.CycleWS (nextScreen, prevScreen, shiftNextScreen, shiftPrevScreen)
import XMonad.Actions.Submap (submap)
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)
import XMonad.Hooks.ManageHelpers (doCenterFloat)
import XMonad.Hooks.StatusBar (defToggleStrutsKey, statusBarProp, withEasySB)
import XMonad.Hooks.StatusBar.PP
import XMonad.Layout.MultiToggle (Toggle (..), mkToggle, single)
import XMonad.Layout.MultiToggle.Instances (StdTransformers (FULL))
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.SimplestFloat (simplestFloat)
import XMonad.Layout.Spacing
import XMonad.Layout.Tabbed
import XMonad.Util.EZConfig (additionalKeys, removeKeys)
import XMonad.Util.SpawnOnce (spawnOnce)
import qualified XMonad.StackSet as W

myModMask :: KeyMask
myModMask = mod4Mask

myTerminal :: String
myTerminal = "st"

myXmobar :: String
myXmobar = "env LANG=C.UTF-8 LC_ALL=C.UTF-8 @xmobar@"

myTrayer :: String
myTrayer =
  unwords
    [ "@trayer@"
    , "--edge"
    , "top"
    , "--align"
    , "right"
    , "--widthtype"
    , "request"
    , "--height"
    , "24"
    , "--transparent"
    , "true"
    , "--alpha"
    , "0"
    , "--tint"
    , "0x1a1b26"
    , "--SetDockType"
    , "true"
    , "--SetPartialStrut"
    , "true"
    , "--padding"
    , "4"
    ]

myKeybinds :: String
myKeybinds = "@keybinds@"

myFocusColor :: String
myFocusColor = "#6dade3"

myUnfocusColor :: String
myUnfocusColor = "#bbbbbb"

myBg :: String
myBg = "#1a1b26"

myCyan :: String
myCyan = "#0db9d7"

myRed :: String
myRed = "#f7768e"

myPurple :: String
myPurple = "#ad8ee6"

myWorkspaces :: [String]
myWorkspaces =
  [ "\xf489"
  , "\xf02af"
  , "\xe745"
  , "\xf198"
  , "\xf066f"
  , "\xf11e4"
  , "\xf16a"
  , "\xf1636"
  , "\xf09ee"
  ]

myTabConfig :: Theme
myTabConfig =
  def
    { fontName = "xft:JetBrainsMono Nerd Font:style=Bold:size=10"
    , activeColor = myBg
    , inactiveColor = myBg
    , urgentColor = myBg
    , activeBorderColor = myFocusColor
    , inactiveBorderColor = myUnfocusColor
    , urgentBorderColor = myRed
    , activeTextColor = myCyan
    , inactiveTextColor = myUnfocusColor
    , urgentTextColor = myRed
    , decoHeight = 22
    }

myLayout =
  mkToggle (single FULL)
    $ smartBorders
    $ spacingRaw True (Border 5 5 5 5) True (Border 5 5 5 5) True
    $ tiled ||| simplestFloat ||| tabbed shrinkText myTabConfig
  where
    tiled = Tall nmaster delta ratio
    nmaster = 1
    ratio = 1 / 2
    delta = 5 / 100

myManageHook :: ManageHook
myManageHook =
  composeAll
    [ className =? "Gimp" --> doCenterFloat
    , className =? "gimp" --> doCenterFloat
    , appName =? "gimp" --> doCenterFloat
    , className =? "mpv" --> doCenterFloat
    , appName =? "mpv" --> doCenterFloat
    , isSt <&&> title =? "hx" --> doCenterFloat
    , isSt <&&> title =? "hx-anywhere" --> doCenterFloat
    , isSt <&&> title =? "nnn" --> doCenterFloat
    , className =? "Pavucontrol" --> doCenterFloat
    , className =? "pavucontrol" --> doCenterFloat
    , className =? "dde-control-center" --> doCenterFloat
    , className =? "fcitx5-configtool" --> doCenterFloat
    , className =? "fcitx-configtool" --> doCenterFloat
    , className =? "aTrustTray2" --> doCenterFloat
    , className =? "aTrustAgent" --> doCenterFloat
    ]
  where
    isSt =
      className
        =? "st"
        <||> className
        =? "St"
        <||> className
        =? "st-256color"
        <||> appName
        =? "st"

myPP :: PP
myPP =
  xmobarPP
    { ppCurrent = xmobarColor myCyan "" . wrap "[" "]"
    , ppVisible = xmobarColor myCyan ""
    , ppHidden = xmobarColor myCyan ""
    , ppHiddenNoWindows = xmobarColor "#bbbbbb" ""
    , ppUrgent = xmobarColor myRed ""
    , ppSep = "  "
    , ppWsSep = " "
    , ppTitle = xmobarColor "#bbbbbb" "" . shorten 40
    , ppLayout = xmobarColor myPurple "" . renameLayout
    }
  where
    renameLayout l
      | "Full" `elem` words (map dashToSpace l) = "[M]"
      | "SimplestFloat" `elem` words (map dashToSpace l) = "[F]"
      | "Tabbed" `elem` words (map dashToSpace l) = "[=]"
      | otherwise = "[T]"
    dashToSpace c
      | c == '-' = ' '
      | otherwise = c

myStartupHook :: X ()
myStartupHook = do
  spawnOnce "st-theme auto"
  spawnOnce "stylix-theme auto"
  spawnOnce "xsetroot -cursor_name left_ptr"
  spawnOnce "oxwm-autostart"
  spawnOnce myTrayer

toggleFloat :: Window -> X ()
toggleFloat w =
  windows $ \s ->
    if M.member w (W.floating s)
      then W.sink w s
      else W.float w (W.RationalRect (1 / 4) (1 / 4) (1 / 2) (1 / 2)) s

toggleGaps :: X ()
toggleGaps = toggleScreenSpacingEnabled >> toggleWindowSpacingEnabled

myKeys :: [((KeyMask, KeySym), X ())]
myKeys =
  [ ((myModMask, xK_Return), spawn myTerminal)
  , ((myModMask, xK_d), spawn "dmenu_run -l 10")
  , ((myModMask, xK_g), spawn "brave")
  , ((myModMask, xK_e), spawn "st -t hx -e hx")
  , ((controlMask .|. mod1Mask, xK_v), spawn "hx-anywhere")
  , ((myModMask, xK_s), spawn "screenshot-to-clipboard")
  , ((myModMask, xK_q), kill)
  , ((myModMask .|. shiftMask, xK_slash), spawn ("st -t keybinds -e less " ++ myKeybinds))
  , ((myModMask, xK_f), withFocused toggleFloat)
  , ((myModMask .|. shiftMask, xK_f), sendMessage (Toggle FULL))
  , ((myModMask .|. shiftMask, xK_space), sendMessage NextLayout)
  , ((myModMask, xK_h), sendMessage Shrink)
  , ((myModMask, xK_l), sendMessage Expand)
  , ((myModMask, xK_i), sendMessage (IncMasterN 1))
  , ((myModMask, xK_p), sendMessage (IncMasterN (-1)))
  , ((myModMask, xK_a), toggleGaps)
  , ((myModMask .|. shiftMask, xK_q), io exitSuccess)
  , ((myModMask .|. shiftMask, xK_r), spawn "xmonad --recompile && xmonad --restart")
  , ((myModMask, xK_j), windows W.focusDown)
  , ((myModMask, xK_k), windows W.focusUp)
  , ((myModMask .|. shiftMask, xK_j), windows W.swapDown)
  , ((myModMask .|. shiftMask, xK_k), windows W.swapUp)
  , ((myModMask, xK_comma), prevScreen)
  , ((myModMask, xK_period), nextScreen)
  , ((myModMask .|. shiftMask, xK_comma), shiftPrevScreen)
  , ((myModMask .|. shiftMask, xK_period), shiftNextScreen)
  , ((myModMask, xK_space), submap . M.fromList $ spaceMap)
  ]
    ++ [ ((m .|. myModMask, k), windows $ f i)
       | (i, k) <- zip myWorkspaces [xK_1 .. xK_9]
       , (f, m) <-
           [ (W.greedyView, 0)
           , (W.shift, shiftMask)
           , (W.view, controlMask)
           , (copy, controlMask .|. shiftMask)
           ]
       ]
  where
    spaceMap =
      [ ((0, xK_t), spawn myTerminal)
      , ((0, xK_n), spawn "st -t nnn -e nnn")
      , ((0, xK_e), spawn "st -t hx -e hx")
      ]

myConfig =
  def
    { modMask = myModMask
    , terminal = myTerminal
    , borderWidth = 2
    , focusedBorderColor = myFocusColor
    , normalBorderColor = myUnfocusColor
    , workspaces = myWorkspaces
    , layoutHook = myLayout
    , manageHook = myManageHook
    , startupHook = myStartupHook
    , focusFollowsMouse = True
    , clickJustFocuses = True
    }
    `removeKeys` [(myModMask, xK_space), (myModMask, xK_p), (myModMask, xK_q)]
    `additionalKeys` myKeys

main :: IO ()
main =
  xmonad
    . ewmhFullscreen
    . ewmh
    . withEasySB (statusBarProp myXmobar (pure myPP)) defToggleStrutsKey
    $ myConfig
