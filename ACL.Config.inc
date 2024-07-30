{$R-} { Range-Checking }
{$Q-} { Overflow checking }
{$Z1} { Minumum enum size = 1}

{$IFDEF FPC}
  {$mode delphi}
  {$modeswitch functionreferences}
  {$modeswitch anonymousfunctions}
  {$modeswitch advancedrecords}
  {$codepage UTF8}
  {$inline off}

  {$H+}
  {$WARN 5024 off} // Parameter "$1" not used
  {$WARN 5026 off}
  {$WARN 6058 off} // Call to subroutine "$1" marked as inline is not inlined
  {$WARN 3124 off} // Inlining disabled

  {$IFNDEF LINUX}
    {$MESSAGE FATAL 'ACL was not ready for other platforms using FPC/LCL'}
  {$ENDIF}

  {$IFDEF LCLGtk2}
    {$DEFINE ACL_CAIRO_TEXTOUT}
  {$ENDIF}

  {$DEFINE DEBUG}
{$ENDIF}


{$IF DEFINED(CPUX64) OR DEFINED(CPU64)}
  {$DEFINE CPUX64}
{$IFEND}


{$IF DEFINED(CPUX64) OR DEFINED(FPC)}
  {$DEFINE ACL_PUREPASCAL}
{$IFEND}


{$IF NOT DEFINED(FPC)}
  {$WARN DUPLICATE_CTOR_DTOR OFF} // We does not support for C++Builder
{$IFEND}


// ---------------------------------------------------------------------------------------------------------------------
// RTTI
// ---------------------------------------------------------------------------------------------------------------------

{$IF NOT DEFINED(ACL_RTTI_ALL) AND NOT DEFINED(FPC)}
  {$WEAKLINKRTTI ON}
  {$IF DEFINED(ACL_RTTI_OFF)}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
  {$ELSE}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([vcPublic, vcPublished])}
  {$IFEND}
{$IFEND}

// ---------------------------------------------------------------------------------------------------------------------
// Options
// ---------------------------------------------------------------------------------------------------------------------

{$IFDEF DEBUG}
  {.$DEFINE ACL_LOG_CMDLINE}
  {.$DEFINE ACL_LOG_FONTCACHE}
  {.$DEFINE ACL_LOG_REGISTRY}
{$ENDIF}

{$DEFINE ACL_BLURFILTER_USE_SHARED_RESOURCES}
{$DEFINE ACL_TEXTLAYOUT_SPANS} // support for complex spans
{$DEFINE ACL_TEXTLAYOUT_RTL}   // support for right-to-left text direction

// Options for TStream.WriteVariant()
{$DEFINE ACL_PACK_VARIANT_ARRAYS}
{$DEFINE ACL_PACK_VARIANT_INTEGERS}

{.$DEFINE ACL_THREADING_DEBUG}
{$DEFINE ACL_THREADING_USE_MESSAGES}

// ---------------------------------------------------------------------------------------------------------------------
// IDE Versions
// ---------------------------------------------------------------------------------------------------------------------

{$IFDEF VER350} // 11.0 Alexandria
  {$DEFINE DELPHI110ALEXANDRIA}
{$ENDIF}

{$IFDEF VER360} // 12.0 Athens
  {$DEFINE DELPHI110ALEXANDRIA}
  {$DEFINE DELPHI120}
{$ENDIF}

{$IF NOT DEFINED(FPC) AND NOT DEFINED(DELPHI110ALEXANDRIA)}
  {$MESSAGE FATAL 'You need Delphi 11.0 Alexandria for this library, previous Delphi versions has too many bugs with dpi scaling'}
{$IFEND}
