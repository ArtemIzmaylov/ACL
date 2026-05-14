{$IFNDEF ACL_CONFIG_INC}
{$DEFINE ACL_CONFIG_INC}

{$R-} { Range-Checking }
{$Q-} { Overflow checking }
{$Z1} { Minumum enum size = 1}

{$POINTERMATH ON}

{$IFDEF FPC}
  {$mode delphi}
  {$modeswitch functionreferences}
  {$modeswitch anonymousfunctions}
  {$modeswitch advancedrecords}
  {$codepage UTF8}
  {$asmmode intel}
  {$inline off}

  {$H+}
  {$DEFINE DEBUG}
  {$WARN 5023 off : Unit "$1" not used in $2}
  {$WARN 5024 off} // Parameter "$1" not used
  {$WARN 5026 off}
  {$WARN 6058 off} // Call to subroutine "$1" marked as inline is not inlined
  {$WARN 3124 off} // Inlining disabled

  {$IF DEFINED(LCLGtk2) OR DEFINED(LCLGtk3)}
    {$DEFINE LCLGtkX}
  {$ELSE}
    // Now, only Gtk2 and Gtk3 widget sets are supported.
    {$MESSAGE FATAL 'ACL is not ready for this WidgetSet'}
  {$ENDIF}
{$ENDIF}

// CPU64 is defined in FreePascal when target is 64-bit
// Win64 is defined in Delphi when target is Windows 64-bit (x86-64 or ARM64EC)
{$IF DEFINED(CPUX64) OR DEFINED(CPU64) OR DEFINED(WIN64)}
  {$DEFINE CPUX64}
{$IFEND}

{$IF DEFINED(FPC) OR DEFINED(CPUX64) OR DEFINED(CPUARM)}
  {$DEFINE ACL_PUREPASCAL} // disable inline assembler
{$IFEND}

{$IF NOT DEFINED(FPC)}
  // Disable some Delphi's warnings
  {$WARN DUPLICATE_CTOR_DTOR OFF}
  {$WARN OVERLOADING_ARRAY_PROPERTY OFF}
{$IFEND}

// -----------------------------------------------------------------------------
// IDE Versions
// -----------------------------------------------------------------------------

{$IFDEF VER350} // Delphi 11 Alexandria
  {$DEFINE DELPHI110ALEXANDRIA}
{$ENDIF}

{$IFDEF VER360} // Delphi 12 Athens
  {$DEFINE DELPHI110ALEXANDRIA}
  {$DEFINE DELPHI120}
{$ENDIF}

{$IFDEF VER370} // Delphi 13 Florence
  {$DEFINE DELPHI110ALEXANDRIA}
  {$DEFINE DELPHI120}
  {$DEFINE DELPHI130}
{$ENDIF}

{$IF NOT DEFINED(FPC) AND NOT DEFINED(DELPHI110ALEXANDRIA)}
  {$MESSAGE FATAL 'You need at least Delphi 11 Alexandria to use this library'}
{$IFEND}

// -----------------------------------------------------------------------------
// RTTI
// -----------------------------------------------------------------------------

{$IF NOT DEFINED(ACL_RTTI_ALL) AND NOT DEFINED(FPC)}
  {$WEAKLINKRTTI ON}
  {$IF DEFINED(ACL_RTTI_OFF)}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
  {$ELSE}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([vcPublished])}
  {$IFEND}
{$IFEND}

// -----------------------------------------------------------------------------
// Options
// -----------------------------------------------------------------------------

{$IF DEFINED(DEBUG)}
  {.$DEFINE ACL_LOG_REGISTRY}
  {$DEFINE ACL_THREADING_DEBUG}
  {$DEFINE ACL_THREADING_DEBUG_DEADLOCKS}
{$ENDIF}

{$DEFINE ACL_ALPHACOMPOSED_POPUPMENUS}
{$DEFINE ACL_TEXTLAYOUT_RTL}  // support for right-to-left text direction

{$IFDEF LCLGtkX}
  {$DEFINE ACL_CAIRO}
  {$DEFINE ACL_CAIRO_RENDER}
  {$DEFINE ACL_CAIRO_TEXTOUT}
{$ENDIF}

{$IFDEF LINUX}
  {.$DEFINE ACL_USE_SKINNED_FORM} // Experimental!
{$ENDIF}

{$ENDIF} // ACL_CONFIG_INC
