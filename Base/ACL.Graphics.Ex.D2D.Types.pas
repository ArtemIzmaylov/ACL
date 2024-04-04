{*********************************************}
{*                                           *}
{*        Artem's Components Library         *}
{*         Extended Graphic Library          *}
{*               Direct2D API                *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2024                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.Graphics.Ex.D2D.Types;

{$I ACL.Config.inc}

{$IFNDEF MSWINDOWS}
  {$MESSAGE FATAL 'Windows platform is required'}
{$ENDIF}

{$ALIGN ON}
{$MINENUMSIZE 4}
{$WEAKPACKAGEUNIT}
{$WARN SYMBOL_PLATFORM OFF}
{$M-}

// WARNING
// This unit contains alternate D2D1 definition, because standard Winapi.D2D1 has a bugs
// and somewhere does not match the Microsoft's documentation

interface

uses
  Winapi.ActiveX,
  Winapi.D2D1,
  Winapi.DxgiFormat,
  Winapi.WinCodec,
  Winapi.Windows;

type
  PIUnknown = ^IUnknown;
  TLargeInteger = Int64;

  TD2D1GradientStops = array of TD2D1GradientStop;

// ---------------------------------------------------------------------------------------------------------------------
// DXGI
// ---------------------------------------------------------------------------------------------------------------------

const
  DXGI_CPU_ACCESS_NONE             = 0;
  {$EXTERNALSYM DXGI_CPU_ACCESS_NONE}
  DXGI_CPU_ACCESS_DYNAMIC          = 1;
  {$EXTERNALSYM DXGI_CPU_ACCESS_DYNAMIC}
  DXGI_CPU_ACCESS_READ_WRITE       = 2;
  {$EXTERNALSYM DXGI_CPU_ACCESS_READ_WRITE}
  DXGI_CPU_ACCESS_SCRATCH          = 3;
  {$EXTERNALSYM DXGI_CPU_ACCESS_SCRATCH}
  DXGI_CPU_ACCESS_FIELD            = 15;
  {$EXTERNALSYM DXGI_CPU_ACCESS_FIELD}

  DXGI_USAGE_SHADER_INPUT          = (1 shl (0 + 4));
  {$EXTERNALSYM DXGI_USAGE_SHADER_INPUT}
  DXGI_USAGE_RENDER_TARGET_OUTPUT  = (1 shl (1 + 4));
  {$EXTERNALSYM DXGI_USAGE_RENDER_TARGET_OUTPUT}
  DXGI_USAGE_BACK_BUFFER           = (1 shl (2 + 4));
  {$EXTERNALSYM DXGI_USAGE_BACK_BUFFER}
  DXGI_USAGE_SHARED                = (1 shl (3 + 4));
  {$EXTERNALSYM DXGI_USAGE_SHARED}
  DXGI_USAGE_READ_ONLY             = (1 shl (4 + 4));
  {$EXTERNALSYM DXGI_USAGE_READ_ONLY}
  DXGI_USAGE_DISCARD_ON_PRESENT    = (1 shl (5 + 4));
  {$EXTERNALSYM DXGI_USAGE_DISCARD_ON_PRESENT}
  DXGI_USAGE_UNORDERED_ACCESS      = (1 shl (6 + 4));
  {$EXTERNALSYM DXGI_USAGE_UNORDERED_ACCESS}

  DXGI_PRESENT_TEST = $00000001;
  {$EXTERNALSYM DXGI_PRESENT_TEST}
  DXGI_PRESENT_DO_NOT_SEQUENCE = $00000002;
  {$EXTERNALSYM DXGI_PRESENT_DO_NOT_SEQUENCE}
  DXGI_PRESENT_RESTART = $00000004;
  {$EXTERNALSYM DXGI_PRESENT_RESTART}
  DXGI_PRESENT_DO_NOT_WAIT = $00000008;
  {$EXTERNALSYM DXGI_PRESENT_DO_NOT_WAIT}
  DXGI_PRESENT_STEREO_PREFER_RIGHT = $00000010;
  {$EXTERNALSYM DXGI_PRESENT_STEREO_PREFER_RIGHT}
  DXGI_PRESENT_STEREO_TEMPORARY_MONO = $00000020;
  {$EXTERNALSYM DXGI_PRESENT_STEREO_TEMPORARY_MONO}
  DXGI_PRESENT_RESTRICT_TO_OUTPUT = $00000040;
  {$EXTERNALSYM DXGI_PRESENT_RESTRICT_TO_OUTPUT}
  DXGI_PRESENT_USE_DURATION = $00000100;
  {$EXTERNALSYM DXGI_PRESENT_USE_DURATION}
  DXGI_PRESENT_ALLOW_TEARING = $00000200;
  {$EXTERNALSYM DXGI_PRESENT_ALLOW_TEARING}

type
  DXGI_USAGE = type UINT;
  {$EXTERNALSYM DXGI_USAGE}
  TDXGIUsage = DXGI_USAGE;

  TDXGIModeRotation = (
    DXGI_MODE_ROTATION_UNSPECIFIED = 0,
    DXGI_MODE_ROTATION_IDENTITY = 1,
    DXGI_MODE_ROTATION_ROTATE90 = 2,
    DXGI_MODE_ROTATION_ROTATE180 = 3,
    DXGI_MODE_ROTATION_ROTATE270= 4
  );

  PDXGIOutputDesc = ^TDXGIOutputDesc;
  TDXGIOutputDesc = record
    DeviceName: array[0..31] of WideChar;
    DesktopCoordinates: TRect;
    AttachedToDesktop: BOOL;
    Rotation: TDXGIModeRotation;
    Monitor: HMONITOR;
  end;

  PDXGIRational = ^TDXGIRational;
  TDXGIRational = record
    Numerator: UINT;
    Denominator: UINT;
  end;

  TDXGIModeScanlineOrder = (
    DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED = 0,
    DXGI_MODE_SCANLINE_ORDER_PROGRESSIVE = 1,
    DXGI_MODE_SCANLINE_ORDER_UPPER_FIELD_FIRST = 2,
    DXGI_MODE_SCANLINE_ORDER_LOWER_FIELD_FIRST = 3
  );

  TDXGIModeScaling = (
    DXGI_MODE_SCALING_UNSPECIFIED = 0,
    DXGI_MODE_SCALING_CENTERED = 1,
    DXGI_MODE_SCALING_STRETCHED = 2
  );

  PDXGIModeDesc = ^TDXGIModeDesc;
  TDXGIModeDesc = record
    Width: UINT;
    Height: UINT;
    RefreshRate: TDXGIRational;
    Format: DXGI_FORMAT;
    ScanlineOrdering: TDXGIModeScanlineOrder;
    Scaling: TDXGIModeScaling;
  end;

  PDXGIGammaControlCapabilities = ^TDXGIGammaControlCapabilities;
  TDXGIGammaControlCapabilities = record
    ScaleAndOffsetSupported: BOOL;
    MaxConvertedValue: Single;
    MinConvertedValue: Single;
    NumGammaControlPoints: UINT;
    ControlPointPositions: array[0..1024] of Single;
  end;

  TDXGIRGB = record
    Red: Single;
    Green: Single;
    Blue: Single;
  end;

  TDXGIRGBA = D3DCOLORVALUE;
  PDXGIRGBA = ^TDXGIRGBA;

  TDXGIGammaControl = record
    Scale: TDXGIRGB;
    Offset: TDXGIRGB;
    GammaCurve: array[0..1024] of TDXGIRGB;
  end;

  PDXGISampleDesc = ^TDXGISampleDesc;
  TDXGISampleDesc = record
    Count: UINT;
    Quality: UINT;
  end;

  PDXGISurfaceDesc = ^TDXGISurfaceDesc;
  TDXGISurfaceDesc = record
    Width: UINT;
    Height: UINT;
    Format: DXGI_FORMAT;
    SampleDesc: TDXGISampleDesc;
  end;

  PDXGIMappedRect = ^TDXGIMappedRect;
  TDXGIMappedRect = record
    Pitch: Integer;
    pBits: PByte;
  end;

  PDXGIFrameStatistics = ^TDXGIFrameStatistics;
  TDXGIFrameStatistics = record
    PresentCount: UINT;
    PresentRefreshCount: UINT;
    SyncRefreshCount: UINT;
    SyncQPCTime: TLargeInteger;
    SyncGPUTime: TLargeInteger;
  end;

  PDXGIAdapterDesc = ^TDXGIAdapterDesc;
  TDXGIAdapterDesc = record
    Description: array[0..127] of WideChar;
    VendorId: UINT;
    DeviceId: UINT;
    SubSysId: UINT;
    Revision: UINT;
    DedicatedVideoMemory: TSize;
    DedicatedSystemMemory: TSize;
    SharedVideoMemory: TSize;
    AdapterLuid: LUID;
  end;

  PDXGISharedResource = ^TDXGISharedResource;
  TDXGISharedResource = record
    Handle: THandle;
  end;

  PDXGIResidency = ^TDXGIResidency;
  TDXGIResidency = (
    DXGI_RESIDENCY_FULLY_RESIDENT = 1,
    DXGI_RESIDENCY_RESIDENT_IN_SHARED_MEMORY = 2,
    DXGI_RESIDENCY_EVICTED_TO_DISK = 3
  );

  TDXGISwapEffect = (
    DXGI_SWAP_EFFECT_DISCARD = 0,
    DXGI_SWAP_EFFECT_SEQUENTIAL = 1,
    DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL = 3,
    DXGI_SWAP_EFFECT_FLIP_DISCARD = 4
  );

const
  DXGI_SWAP_CHAIN_FLAG_NONPREROTATED = 1;
  DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH = 2;
  DXGI_SWAP_CHAIN_FLAG_GDI_COMPATIBLE = 4;
  DXGI_SWAP_CHAIN_FLAG_RESTRICTED_CONTENT = 8;
  DXGI_SWAP_CHAIN_FLAG_RESTRICT_SHARED_RESOURCE_DRIVER = 16;
  DXGI_SWAP_CHAIN_FLAG_DISPLAY_ONLY = 32;
  DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT = 64;
  DXGI_SWAP_CHAIN_FLAG_FOREGROUND_LAYER = 128;
  DXGI_SWAP_CHAIN_FLAG_FULLSCREEN_VIDEO = 256;
  DXGI_SWAP_CHAIN_FLAG_YUV_VIDEO = 512;
  DXGI_SWAP_CHAIN_FLAG_HW_PROTECTED = 1024;
  DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING = 2048;
  DXGI_SWAP_CHAIN_FLAG_RESTRICTED_TO_ALL_HOLOGRAPHIC_DISPLAYS = 4096;

const
  DXGI_FAC = $87A;
  MAKE_DXGI_HRESULT = longint(DXGI_FAC shl 16) or longint(1 shl 31);
  MAKE_DXGI_STATUS = longint(DXGI_FAC shl 16);

  DXGI_STATUS_OCCLUDED = MAKE_DXGI_STATUS or 1;
  {$EXTERNALSYM DXGI_STATUS_OCCLUDED}
  DXGI_STATUS_CLIPPED = MAKE_DXGI_STATUS or 2;
  {$EXTERNALSYM DXGI_STATUS_CLIPPED}
  DXGI_STATUS_NO_REDIRECTION = MAKE_DXGI_STATUS or 4;
  {$EXTERNALSYM DXGI_STATUS_NO_REDIRECTION}
  DXGI_STATUS_NO_DESKTOP_ACCESS = MAKE_DXGI_STATUS or 5;
  {$EXTERNALSYM DXGI_STATUS_NO_DESKTOP_ACCESS}
  DXGI_STATUS_GRAPHICS_VIDPN_SOURCE_IN_USE = MAKE_DXGI_STATUS or 6;
  {$EXTERNALSYM DXGI_STATUS_GRAPHICS_VIDPN_SOURCE_IN_USE}
  DXGI_STATUS_MODE_CHANGED = MAKE_DXGI_STATUS or 7;
  {$EXTERNALSYM DXGI_STATUS_MODE_CHANGED}
  DXGI_STATUS_MODE_CHANGE_IN_PROGRESS = MAKE_DXGI_STATUS or 8;
  {$EXTERNALSYM DXGI_STATUS_MODE_CHANGE_IN_PROGRESS}

  DXGI_ERROR_INVALID_CALL = MAKE_DXGI_HRESULT or 1;
  {$EXTERNALSYM DXGI_ERROR_INVALID_CALL}
  DXGI_ERROR_NOT_FOUND = MAKE_DXGI_HRESULT or 2;
  {$EXTERNALSYM DXGI_ERROR_NOT_FOUND}
  DXGI_ERROR_MORE_DATA = MAKE_DXGI_HRESULT or 3;
  {$EXTERNALSYM DXGI_ERROR_MORE_DATA}
  DXGI_ERROR_UNSUPPORTED = MAKE_DXGI_HRESULT or 4;
  {$EXTERNALSYM DXGI_ERROR_UNSUPPORTED}
  DXGI_ERROR_DEVICE_REMOVED = MAKE_DXGI_HRESULT or 5;
  {$EXTERNALSYM DXGI_ERROR_DEVICE_REMOVED}
  DXGI_ERROR_DEVICE_HUNG = MAKE_DXGI_HRESULT or 6;
  {$EXTERNALSYM DXGI_ERROR_DEVICE_HUNG}
  DXGI_ERROR_DEVICE_RESET = MAKE_DXGI_HRESULT or 7;
  {$EXTERNALSYM DXGI_ERROR_DEVICE_RESET}
  DXGI_ERROR_WAS_STILL_DRAWING = MAKE_DXGI_HRESULT or 10;
  {$EXTERNALSYM DXGI_ERROR_WAS_STILL_DRAWING}
  DXGI_ERROR_FRAME_STATISTICS_DISJOINT = MAKE_DXGI_HRESULT or 11;
  {$EXTERNALSYM DXGI_ERROR_FRAME_STATISTICS_DISJOINT}
  DXGI_ERROR_GRAPHICS_VIDPN_SOURCE_IN_USE = MAKE_DXGI_HRESULT or 12;
  {$EXTERNALSYM DXGI_ERROR_GRAPHICS_VIDPN_SOURCE_IN_USE}
  DXGI_ERROR_DRIVER_INTERNAL_ERROR = MAKE_DXGI_HRESULT or 32;
  {$EXTERNALSYM DXGI_ERROR_DRIVER_INTERNAL_ERROR}
  DXGI_ERROR_NONEXCLUSIVE = MAKE_DXGI_HRESULT or 33;
  {$EXTERNALSYM DXGI_ERROR_NONEXCLUSIVE}
  DXGI_ERROR_NOT_CURRENTLY_AVAILABLE = MAKE_DXGI_HRESULT or 34;
  {$EXTERNALSYM DXGI_ERROR_NOT_CURRENTLY_AVAILABLE}
  DXGI_ERROR_REMOTE_CLIENT_DISCONNECTED = MAKE_DXGI_HRESULT or 35;
  {$EXTERNALSYM DXGI_ERROR_REMOTE_CLIENT_DISCONNECTED}
  DXGI_ERROR_REMOTE_OUTOFMEMORY = MAKE_DXGI_HRESULT or 36;
  {$EXTERNALSYM DXGI_ERROR_REMOTE_OUTOFMEMORY}

type
  PDXGIModeDesc1 = ^TDXGIModeDesc1;
  TDXGIModeDesc1 = record
    Width: UINT;
    Height: UINT;
    RefreshRate: TDXGIRational;
    Format: DXGI_FORMAT;
    ScanlineOrdering: TDXGIModeScanlineOrder;
    Scaling: TDXGIModeScaling;
    Stereo: LongBool;
  end;

  TDXGIScaling = (
    DXGI_SCALING_STRETCH = 0,
    DXGI_SCALING_NONE = 1,
    DXGI_SCALING_ASPECT_RATIO_STRETCH = 2
  );

  TDXGIAlphaMode = (
    DXGI_ALPHA_MODE_UNSPECIFIED = 0,
    DXGI_ALPHA_MODE_PREMULTIPLIED = 1,
    DXGI_ALPHA_MODE_STRAIGHT = 2,
    DXGI_ALPHA_MODE_IGNORE = 3
  );

  PDXGISwapChainDesc1 = ^TDXGISwapChainDesc1;
  TDXGISwapChainDesc1 = record
    Width: UINT;
    Height: UINT;
    Format: DXGI_FORMAT;
    Stereo: LongBool;
    SampleDesc: TDXGISampleDesc;
    BufferUsage: TDXGIUsage;
    BufferCount: UINT;
    Scaling: TDXGIScaling;
    SwapEffect: TDXGISwapEffect;
    AlphaMode: TDXGIAlphaMode;
    Flags: UINT;
  end;

  PDXGISwapChainFullScreenDesc = ^TDXGISwapChainFullScreenDesc;
  TDXGISwapChainFullScreenDesc = record
    RefreshRate: TDXGIRational;
    ScanlineOrdering: TDXGIModeScanlineOrder;
    Scaling: TDXGIModeScaling;
    Windowed: LongBool;
  end;

  PDXGIPresentParameters = ^TDXGIPresentParameters;
  TDXGIPresentParameters = record
    DirtyRectsCount: UINT;
    pDirtyRects: PRECT;
    pScrollRect: PRECT;
    pScrollOffset: PPOINT;
  end;

  PDXGISwapChainDesc = ^TDXGISwapChainDesc;
  TDXGISwapChainDesc = record
    BufferDesc: TDXGIModeDesc;
    SampleDesc: TDXGISampleDesc;
    BufferUsage: TDXGIUsage;
    BufferCount: UINT;
    OutputWindow: HWND;
    Windowed: LongBool;
    SwapEffect: TDXGISwapEffect;
    Flags: UINT;
  end;

  TDXGIAdapterDesc1 = record
    Description: array [0.. 127] of WideChar;
    VendorId: UINT;
    DeviceId: UINT;
    SubSysId: UINT;
    Revision: UINT;
    DedicatedVideoMemory: TSize;
    DedicatedSystemMemory: TSize;
    SharedSystemMemory: TSize;
    AdapterLuid: TLUID;
    Flags: UINT;
  end;

  IDXGIObject = interface(IUnknown)
  ['{aec22fb8-76f3-4639-9be0-28eb43a67a2e}']
    function SetPrivateData(const Name: TGUID; DataSize: UINT; pData: Pointer): HResult; stdcall;
    function SetPrivateDataInterface(const Name: TGUID; const pUnknown: IUnknown): HResult; stdcall;
    function GetPrivateData(const Name: TGUID; var pDataSize: UINT; pData: Pointer): HResult; stdcall;
    function GetParent(const riid: TIID; out ppParent{IUnknown}): HResult; stdcall;
  end;

  IDXGIDeviceSubObject = interface(IDXGIObject)
  ['{3d3e0379-f9de-4d58-bb6c-18d62992f1a6}']
    function GetDevice(const riid: TIID; out ppDevice{IUnknown}): HResult; stdcall;
  end;

  IDXGISurface = interface(IDXGIDeviceSubObject)
  ['{cafcb56c-6ac3-4889-bf47-9e23bbd260ec}']
    function GetDesc(out pDesc: TDXGISurfaceDesc): HResult; stdcall;
    function Map(out pLockedRect: TDXGIMappedRect; MapFlags: UINT): HResult; stdcall;
    function Unmap: HResult; stdcall;
  end;

  IDXGISurface1 = interface(IDXGISurface)
  ['{4AE63092-6327-4c1b-80AE-BFE12EA32B86}']
    function GetDC(Discard: BOOL; out hdc: HDC): HResult; stdcall;
    function ReleaseDC(pDirtyRect: PRect): HResult; stdcall;
  end;

  IDXGIOutput = interface(IDXGIObject)
  ['{ae02eedb-c735-4690-8d52-5a8dc20213aa}']
    function GetDesc(out pDesc: TDXGIOutputDesc): HResult; stdcall;
    function GetDisplayModeList(EnumFormat: DXGI_FORMAT; Flags: UINT; var pNumModes: UINT; pDesc: PDXGIModeDesc): HResult; stdcall;
    function FindClosestMatchingMode(const pModeToMatch: TDXGIModeDesc;
      out pClosestMatch: TDXGIModeDesc; const pConcernedDevice: IUnknown): HResult; stdcall;
    function WaitForVBlank: HResult; stdcall;
    function TakeOwnership(const pDevice: IUnknown; Exclusive: BOOL): HResult; stdcall;
    function ReleaseOwnership: HResult; stdcall;
    function GetGammaControlCapabilities(out pGammaCaps: TDXGIGammaControlCapabilities): HResult; stdcall;
    function SetGammaControl(const pArray: TDXGIGammaControl): HResult; stdcall;
    function GetGammaControl(out pArray: TDXGIGammaControl): HResult; stdcall;
    function SetDisplaySurface(const pScanOutSurface: IDXGISurface): HResult; stdcall;
    function GetDisplaySurfaceData(const pDestination: IDXGISurface): HResult; stdcall;
    function GetFrameStatistics(out pStats: TDXGIFrameStatistics): HResult; stdcall;
  end;

  IDXGIAdapter = interface(IDXGIObject)
  ['{2411e7e1-12ac-4ccf-bd14-9798e8534dc0}']
    function EnumOutputs(Output: UINT; out ppOutput: IDXGIOutput): HResult; stdcall;
    function GetDesc(out pDesc: TDXGIAdapterDesc): HResult; stdcall;
    function CheckInterfaceSupport(const InterfaceName: TGUID; out pUMDVersion: TLargeInteger): HResult; stdcall;
  end;

  IDXGIDevice = interface(IDXGIObject)
  ['{54ec77fa-1377-44e6-8c32-88fd5f44c84c}']
    function GetAdapter(out pAdapter: IDXGIAdapter): HResult; stdcall;
    function CreateSurface(const pDesc: TDXGISurfaceDesc; NumSurfaces: UINT; Usage: TDXGIUsage;
      const pSharedResource: TDXGISharedResource; out ppSurface: IDXGISurface): HResult; stdcall;
    function QueryResourceResidency(const ppResources: PIUnknown;
      out pResidencyStatus: PDXGIResidency; NumResources: UINT): HResult; stdcall;
    function SetGPUThreadPriority(Priority: Integer): HResult; stdcall;
    function GetGPUThreadPriority(out pPriority: Integer): HResult; stdcall;
  end;

  IDXGIDevice1 = interface(IDXGIDevice)
  ['{77db970f-6276-48ba-ba28-070143b4392c}']
    function SetMaximumFrameLatency(MaxLatency: UINT): HResult; stdcall;
    function GetMaximumFrameLatency(out pMaxLatency: UINT): HResult; stdcall;
  end;

  IDXGISwapChain = interface(IDXGIDeviceSubObject)
  ['{310d36a0-d2e7-4c0a-aa04-6a9d23b8886a}']
    function Present(SyncInterval: UINT; Flags: UINT): HResult; stdcall;
    function GetBuffer(Buffer: UINT; const riid: TGUID; out ppSurface): HResult; stdcall;
    function SetFullScreenState(FullScreen: LongBool; pTarget: IDXGIOutput): HResult; stdcall;
    function GetFullScreenState(out pFullScreen: LongBool; out ppTarget: IDXGIOutput): HResult; stdcall;
    function GetDesc(out pDesc: TDXGISwapChainDesc): HResult; stdcall;
    function ResizeBuffers(BufferCount: UINT; Width: UINT; Height: UINT; NewFormat: DXGI_FORMAT; SwapChainFlags: UINT): HResult; stdcall;
    function ResizeTarget(const pNewTargetParameters: PDXGIModeDesc): HResult; stdcall;
    function GetContainingOutput(out ppOutput: IDXGIOutput): HResult; stdcall;
    function GetFrameStatistics(out pStats: TDXGIFrameStatistics): HResult; stdcall;
    function GetLastPresentCount(out pLastPresentCount: UINT): HResult; stdcall;
  end;

  IDXGISwapChain1 = interface(IDXGISwapChain)
  ['{790a45f7-0d42-4876-983a-0a55cfe6f4aa}']
    function GetDesc1(out pDesc: TDXGISwapChainDesc1): HResult; stdcall;
    function GetFullScreenDesc(out pDesc: TDXGISwapChainFullScreenDesc): HResult; stdcall;
    function GetHwnd(out pHwnd: HWND): HResult; stdcall;
    function GetCoreWindow(RefIID: TGUID; out ppUnk: pointer): HResult; stdcall;
    function Present1(SyncInterval: UINT; PresentFlags: UINT; pPresentParameters: PDXGIPresentParameters): HResult; stdcall;
    function IsTemporaryMonoSupported: LongBool; stdcall;
    function GetRestrictToOutput(out ppRestrictToOutput: IDXGIOutput): HResult; stdcall;
    function SetBackgroundColor(pColor: PDXGIRGBA): HResult; stdcall;
    function GetBackgroundColor(out pColor: TDXGIRGBA): HResult; stdcall;
    function SetRotation(Rotation: TDXGIModeRotation): HResult; stdcall;
    function GetRotation(out pRotation: TDXGIModeRotation): HResult; stdcall;
  end;

  IDXGIFactory = interface(IDXGIObject)
  ['{7b7166ec-21c7-44ae-b21a-c9ae321ae369}']
    function EnumAdapters(Adapter: UINT; out ppAdapter: IDXGIAdapter): HResult; stdcall;
    function MakeWindowAssociation(WindowHandle: HWND; Flags: UINT): HResult; stdcall;
    function GetWindowAssociation(out pWindowHandle: HWND): HResult; stdcall;
    function CreateSwapChain(pDevice: IUnknown; pDesc: PDXGISwapChainDesc; out ppSwapChain: IDXGISwapChain): HResult; stdcall;
    function CreateSoftwareAdapter(Module: HMODULE; out ppAdapter: IDXGIAdapter): HResult; stdcall;
  end;

  IDXGIAdapter1 = interface(IDXGIAdapter)
  ['{29038f61-3839-4626-91fd-086879011a05}']
    function GetDesc1(out pDesc: TDXGIAdapterDesc1): HResult; stdcall;
  end;

  IDXGIFactory1 = interface(IDXGIFactory)
  ['{770aae78-f26f-4dba-a829-253c83d1b387}']
    function EnumAdapters1(Adapter: UINT; out ppAdapter: IDXGIAdapter1): HResult; stdcall;
    function IsCurrent: LongBool; stdcall;
  end;

  IDXGIFactory2 = interface(IDXGIFactory1)
  ['{50c83a1c-e072-4c48-87b0-3630fa36a6d0}']
    function IsWindowedStereoEnabled(): LongBool; stdcall;
    function CreateSwapChainForHwnd(pDevice: IUnknown; hWnd: HWND; pDesc: PDXGISwapChainDesc1;
      pFullScreenDesc: PDXGISwapChainFullScreenDesc; pRestrictToOutput: IDXGIOutput; out ppSwapChain: IDXGISwapChain1): HResult; stdcall;
    function CreateSwapChainForCoreWindow(pDevice: IUnknown; pWindow: IUnknown; pDesc: PDXGISwapChainDesc1;
      pRestrictToOutput: IDXGIOutput; out ppSwapChain: IDXGISwapChain1): HResult; stdcall;
    function GetSharedResourceAdapterLuid(hResource: THANDLE; out pLuid: TLUID): HResult; stdcall;

    function RegisterStereoStatusWindow(WindowHandle: HWND; wMsg: UINT; out pdwCookie: DWORD): HResult; stdcall;
    function RegisterStereoStatusEvent(hEvent: THANDLE; out pdwCookie: DWORD): HResult; stdcall;
    procedure UnregisterStereoStatus(dwCookie: DWORD); stdcall;
    function RegisterOcclusionStatusWindow(WindowHandle: HWND; wMsg: UINT; out pdwCookie: DWORD): HResult; stdcall;
    function RegisterOcclusionStatusEvent(hEvent: THANDLE; out pdwCookie: DWORD): HResult; stdcall;
    procedure UnregisterOcclusionStatus(dwCookie: DWORD); stdcall;
    function CreateSwapChainForComposition(pDevice: IUnknown; pDesc: PDXGISwapChainDesc1;
      pRestrictToOutput: IDXGIOutput; out ppSwapChain: IDXGISwapChain1): HResult; stdcall;
  end;

// ---------------------------------------------------------------------------------------------------------------------
// D2D1
// ---------------------------------------------------------------------------------------------------------------------

const
  SID_ID2D1Factory1 = '{bb12d362-daee-4b9a-aa1d-14ba401cfa1f}';
  IID_ID2D1Factory1: TGUID = SID_ID2D1Factory1;

  SID_ID2D1DeviceContext = '{e8f7fe7a-191c-466d-ad95-975678bda998}';
  IID_ID2D1DeviceContext: TGUID = SID_ID2D1DeviceContext;

  SID_ID2D1Device = '{47dd575d-ac05-4cdd-8049-9b02cd16f44c}';
  IID_ID2D1Device: TGUID = SID_ID2D1Device;

const
  D2D1_INTERPOLATION_MODE_DEFINITION_NEAREST_NEIGHBOR = 0;
  D2D1_INTERPOLATION_MODE_DEFINITION_LINEAR = 1;
  D2D1_INTERPOLATION_MODE_DEFINITION_CUBIC = 2;
  D2D1_INTERPOLATION_MODE_DEFINITION_MULTI_SAMPLE_LINEAR = 3;
  D2D1_INTERPOLATION_MODE_DEFINITION_ANISOTROPIC = 4;
  D2D1_INTERPOLATION_MODE_DEFINITION_HIGH_QUALITY_CUBIC = 5;
  D2D1_INTERPOLATION_MODE_DEFINITION_FANT = 6;
  D2D1_INTERPOLATION_MODE_DEFINITION_MIPMAP_LINEAR = 7;

type
  TD2D1BitmapOptions = type Integer;

const
  D2D1_BITMAP_OPTIONS_NONE = $00000000;
  D2D1_BITMAP_OPTIONS_TARGET = $00000001;
  D2D1_BITMAP_OPTIONS_CANNOT_DRAW = $00000002;
  D2D1_BITMAP_OPTIONS_CPU_READ = $00000004;
  D2D1_BITMAP_OPTIONS_GDI_COMPATIBLE = $00000008;

type
  TD2D1ColorSpace = (
    D2D1_COLOR_SPACE_CUSTOM = 0,
    D2D1_COLOR_SPACE_SRGB = 1,
    D2D1_COLOR_SPACE_SCRGB = 2
  );

  PD2D1MappedRect = ^TD2D1MappedRect;
  TD2D1MappedRect = record
    pitch: UINT32;
    bits: PBYTE;
  end;

  TD2D1PropertyType = (
    D2D1_PROPERTY_TYPE_UNKNOWN = 0,
    D2D1_PROPERTY_TYPE_STRING = 1,
    D2D1_PROPERTY_TYPE_BOOL = 2,
    D2D1_PROPERTY_TYPE_UINT32 = 3,
    D2D1_PROPERTY_TYPE_INT32 = 4,
    D2D1_PROPERTY_TYPE_FLOAT = 5,
    D2D1_PROPERTY_TYPE_VECTOR2 = 6,
    D2D1_PROPERTY_TYPE_VECTOR3 = 7,
    D2D1_PROPERTY_TYPE_VECTOR4 = 8,
    D2D1_PROPERTY_TYPE_BLOB = 9,
    D2D1_PROPERTY_TYPE_IUNKNOWN = 10,
    D2D1_PROPERTY_TYPE_ENUM = 11,
    D2D1_PROPERTY_TYPE_ARRAY = 12,
    D2D1_PROPERTY_TYPE_CLSID = 13,
    D2D1_PROPERTY_TYPE_MATRIX_3X2 = 14,
    D2D1_PROPERTY_TYPE_MATRIX_4X3 = 15,
    D2D1_PROPERTY_TYPE_MATRIX_4X4 = 16,
    D2D1_PROPERTY_TYPE_MATRIX_5X4 = 17,
    D2D1_PROPERTY_TYPE_COLOR_CONTEXT = 18
  );

type
  TD2D1Property = type Integer;

const
  D2D1_PROPERTY_CLSID = $80000000;
  D2D1_PROPERTY_DISPLAYNAME = $80000001;
  D2D1_PROPERTY_AUTHOR = $80000002;
  D2D1_PROPERTY_CATEGORY = $80000003;
  D2D1_PROPERTY_DESCRIPTION = $80000004;
  D2D1_PROPERTY_INPUTS = $80000005;
  D2D1_PROPERTY_CACHED = $80000006;
  D2D1_PROPERTY_PRECISION = $80000007;
  D2D1_PROPERTY_MIN_INPUTS = $80000008;
  D2D1_PROPERTY_MAX_INPUTS = $80000009;

type
  TD2D1SubProperty = type Integer;

const
  D2D1_SUBPROPERTY_DISPLAYNAME = $80000000;
  D2D1_SUBPROPERTY_ISREADONLY = $80000001;
  D2D1_SUBPROPERTY_MIN = $80000002;
  D2D1_SUBPROPERTY_MAX = $80000003;
  D2D1_SUBPROPERTY_DEFAULT = $80000004;
  D2D1_SUBPROPERTY_FIELDS = $80000005;
  D2D1_SUBPROPERTY_INDEX = $80000006;

type
  TD2D1BufferPrecision = (
    D2D1_BUFFER_PRECISION_UNKNOWN = 0,
    D2D1_BUFFER_PRECISION_8BPC_UNORM = 1,
    D2D1_BUFFER_PRECISION_8BPC_UNORM_SRGB = 2,
    D2D1_BUFFER_PRECISION_16BPC_UNORM = 3,
    D2D1_BUFFER_PRECISION_16BPC_FLOAT = 4,
    D2D1_BUFFER_PRECISION_32BPC_FLOAT = 5
  );

  TD2D1ColorInterpolationMode = (
    D2D1_COLOR_INTERPOLATION_MODE_STRAIGHT = 0,
    D2D1_COLOR_INTERPOLATION_MODE_PREMULTIPLIED = 1
  );

  TD2D1MapOptions = (
    D2D1_MAP_OPTIONS_NONE = 0,
    D2D1_MAP_OPTIONS_READ = 1,
    D2D1_MAP_OPTIONS_WRITE = 2,
    D2D1_MAP_OPTIONS_DISCARD = 4
  );

  TD2D1InterpolationMode = (
    D2D1_INTERPOLATION_MODE_NEAREST_NEIGHBOR = D2D1_INTERPOLATION_MODE_DEFINITION_NEAREST_NEIGHBOR,
    D2D1_INTERPOLATION_MODE_LINEAR = D2D1_INTERPOLATION_MODE_DEFINITION_LINEAR,
    D2D1_INTERPOLATION_MODE_CUBIC = D2D1_INTERPOLATION_MODE_DEFINITION_CUBIC,
    D2D1_INTERPOLATION_MODE_MULTI_SAMPLE_LINEAR = D2D1_INTERPOLATION_MODE_DEFINITION_MULTI_SAMPLE_LINEAR,
    D2D1_INTERPOLATION_MODE_ANISOTROPIC = D2D1_INTERPOLATION_MODE_DEFINITION_ANISOTROPIC,
    D2D1_INTERPOLATION_MODE_HIGH_QUALITY_CUBIC = D2D1_INTERPOLATION_MODE_DEFINITION_HIGH_QUALITY_CUBIC
  );


  PD2D1ImageBrushProperties = ^TD2D1ImageBrushProperties;
  TD2D1ImageBrushProperties = record
    sourceRectangle: TD2D1RectF;
    extendModeX: TD2D1ExtendMode;
    extendModeY: TD2D1ExtendMode;
    interpolationMode: TD2D1InterpolationMode;
  end;

  PD2D1BitmapBrushProperties1 = ^TD2D1BitmapBrushProperties1;
  TD2D1BitmapBrushProperties1 = record
    extendModeX: TD2D1ExtendMode;
    extendModeY: TD2D1ExtendMode;
    interpolationMode: TD2D1InterpolationMode;
  end;

  PD2D1RenderingControls = ^TD2D1RenderingControls;
  TD2D1RenderingControls = record
    bufferPrecision: TD2D1BufferPrecision;
    tileSize: TD2D1SizeU;
  end;

  TD2D1PrimitiveBlend = (
    D2D1_PRIMITIVE_BLEND_SOURCE_OVER = 0,
    D2D1_PRIMITIVE_BLEND_COPY = 1,
    D2D1_PRIMITIVE_BLEND_MIN = 2,
    D2D1_PRIMITIVE_BLEND_ADD = 3,
    D2D1_PRIMITIVE_BLEND_MAX = 4
  );

  TD2D1CompositeMode = (
    D2D1_COMPOSITE_MODE_SOURCE_OVER = 0,
    D2D1_COMPOSITE_MODE_DESTINATION_OVER = 1,
    D2D1_COMPOSITE_MODE_SOURCE_IN = 2,
    D2D1_COMPOSITE_MODE_DESTINATION_IN = 3,
    D2D1_COMPOSITE_MODE_SOURCE_OUT = 4,
    D2D1_COMPOSITE_MODE_DESTINATION_OUT = 5,
    D2D1_COMPOSITE_MODE_SOURCE_ATOP = 6,
    D2D1_COMPOSITE_MODE_DESTINATION_ATOP = 7,
    D2D1_COMPOSITE_MODE_XOR = 8,
    D2D1_COMPOSITE_MODE_PLUS = 9,
    D2D1_COMPOSITE_MODE_SOURCE_COPY = 10,
    D2D1_COMPOSITE_MODE_BOUNDED_SOURCE_COPY = 11,
    D2D1_COMPOSITE_MODE_MASK_INVERT = 12
  );

  TD2D1DeviceContextOptions = (
    D2D1_DEVICE_CONTEXT_OPTIONS_NONE = 0,
    D2D1_DEVICE_CONTEXT_OPTIONS_ENABLE_MULTITHREADED_OPTIMIZATIONS = 1
  );

  TD2D1UnitMode = (
    D2D1_UNIT_MODE_DIPS = 0,
    D2D1_UNIT_MODE_PIXELS = 1
  );

  PD2D1LayerParameters1 = ^TD2D1LayerParameters1;
  TD2D1LayerParameters1 = record
    contentBounds: TD2D1RectF;
    geometricMask: ID2D1Geometry;
    maskAntiAliasMode: TD2D1AntiAliasMode;
    maskTransform: TD2D1Matrix3x2F;
    opacity: single;
    opacityBrush: ID2D1Brush;
    layerOptions: TD2D1LayerOptions;
  end;


  TD2D1StrokeTransformType = (
    D2D1_STROKE_TRANSFORM_TYPE_NORMAL = 0,
    D2D1_STROKE_TRANSFORM_TYPE_FIXED = 1,
    D2D1_STROKE_TRANSFORM_TYPE_HAIRLINE = 2
  );

  PD2D1StrokeStyleProperties1 = ^TD2D1StrokeStyleProperties1;
  TD2D1StrokeStyleProperties1 = record
    startCap: TD2D1CapStyle;
    endCap: TD2D1CapStyle;
    dashCap: TD2D1CapStyle;
    lineJoin: TD2D1LineJoin;
    miterLimit: single;
    dashStyle: TD2D1DashStyle;
    dashOffset: single;
    transformType: TD2D1StrokeTransformType;
  end;

  PD2D1PointDescription = ^TD2D1PointDescription;
  TD2D1PointDescription = record
    point: TD2D1Point2F;
    unitTangentVector: TD2D1Point2F;
    endSegment: UINT32;
    endFigure: UINT32;
    lengthToEndSegment: single;
  end;

  PD2D1DrawingStateDescription1 = ^TD2D1DrawingStateDescription1;
  TD2D1DrawingStateDescription1 = record
    antiAliasMode: TD2D1AntiAliasMode;
    textAntiAliasMode: TD2D1TextAntiAliasMode;
    tag1: TD2D1Tag;
    tag2: TD2D1Tag;
    transform: TD2D1Matrix3x2F;
    primitiveBlend: TD2D1PrimitiveBlend;
    unitMode: TD2D1UnitMode;
  end;

  TD2D1PropertySetFunc = function(effect: IUnknown; Data: PBYTE; dataSize: UINT32): HResult; stdcall;
  TD2D1PropertyGetFunc = function(effect: IUnknown; out Data: PBYTE; dataSize: UINT32; out actualSize: UINT32): HResult; stdcall;

  PD2D1PropertyBinding = ^TD2D1PropertyBinding;
  TD2D1PropertyBinding = record
    propertyName: PWideChar;
    setFunction: TD2D1PropertySetFunc;
    getFunction: TD2D1PropertyGetFunc;
  end;

  ID2D1RenderTarget = interface;
  ID2D1ColorContext = interface;
  ID2D1Effect = interface;

  PD2D1BitmapProperties1 = ^TD2D1BitmapProperties1;
  TD2D1BitmapProperties1 = record
    pixelFormat: TD2D1PixelFormat;
    dpiX: single;
    dpiY: single;
    bitmapOptions: TD2D1BitmapOptions;
    colorContext: ID2D1ColorContext;
  end;

  ID2D1ColorContext = interface(ID2D1Resource)
  ['{1c4820bb-5771-4518-a581-2fe4dd0ec657}']
    function GetColorSpace: TD2D1ColorSpace; stdcall;
    function GetProfileSize: UINT32; stdcall;
    function GetProfile(out profile: PBYTE; profileSize: UINT32): HResult; stdcall;
  end;

  ID2D1Image = interface(ID2D1Resource)
  ['{65019f75-8da2-497c-b32c-dfa34e48ede6}']
  end;

  ID2D1Bitmap = interface(ID2D1Image)
  [SID_ID2D1Bitmap]
    // Returns the size of the bitmap in resolution independent units.
    procedure GetSize(out size: TD2D1SizeF); stdcall;
    // Returns the size of the bitmap in resolution dependent units, (pixels).
    procedure GetPixelSize(out pixelSize: TD2D1SizeU); stdcall;
    // Retrieve the format of the bitmap.
    procedure GetPixelFormat(out pixelFormat: TD2D1PixelFormat); stdcall;
    // Return the DPI of the bitmap.
    procedure GetDpi(out dpiX, dpiY: Single); stdcall;
    function CopyFromBitmap(var destPoint: D2D1_POINT_2U; const bitmap: ID2D1Bitmap; var srcRect: D2D1_RECT_U): HResult; stdcall;
    function CopyFromRenderTarget(var destPoint: D2D1_POINT_2U;
      const renderTarget: ID2D1RenderTarget; var srcRect: D2D1_RECT_U): HResult; stdcall;
    function CopyFromMemory(var dstRect: D2D1_RECT_U; srcData: Pointer; pitch: Cardinal): HResult; stdcall;
  end;

  ID2D1Bitmap1 = interface(ID2D1Bitmap)
  ['{a898a84c-3873-4588-b08b-ebbf978df041}']
    procedure GetColorContext(out colorContext: ID2D1ColorContext); stdcall;
    function GetOptions: TD2D1BitmapOptions; stdcall;
    function GetSurface(out dxgiSurface: IDXGISurface): HResult; stdcall;
    function Map(options: TD2D1MapOptions; out mappedRect: TD2D1MappedRect): HResult; stdcall;
    function Unmap: HResult; stdcall;
  end;

  ID2D1Properties = interface(IUnknown)
  ['{483473d7-cd46-4f9d-9d3a-3112aa80159d}']
    function GetPropertyCount: UINT32; stdcall;
    function GetPropertyName(index: UINT32; out Name: PWideChar; nameCount: UINT32): HResult; stdcall;
    function GetPropertyNameLength(index: UINT32): UINT32; stdcall;
    function GetType(index: UINT32): TD2D1PropertyType; stdcall;
    function GetPropertyIndex(Name: PWideChar): UINT32; stdcall;
    function SetValueByName(Name: PWideChar; _type: TD2D1PropertyType; Data: PBYTE; dataSize: UINT32): HResult; stdcall;
    function SetValue(index: UINT32; _type: TD2D1PropertyType; Data: PBYTE; dataSize: UINT32): HResult; stdcall;
    function GetValueByName(Name: PWideChar; _type: TD2D1PropertyType; out Data: PBYTE; dataSize: UINT32): HResult; stdcall;
    function GetValue(index: UINT32; _type: TD2D1PropertyType; out Data: PBYTE; dataSize: UINT32): HResult; stdcall;
    function GetValueSize(index: UINT32): UINT32; stdcall;
    function GetSubProperties(index: UINT32; out subProperties: ID2D1Properties): HResult; stdcall;
  end;

  ID2D1Effect = interface(ID2D1Properties)
  ['{28211a43-7d89-476f-8181-2d6159b220ad}']
    procedure SetInput(index: UINT32; input: ID2D1Image; invalidate: LongBool = True); stdcall;
    function SetInputCount(inputCount: UINT32): HResult; stdcall;
    procedure GetInput(index: UINT32; out input: ID2D1Image); stdcall;
    function GetInputCount: UINT32; stdcall;
    procedure GetOutput(out outputImage: ID2D1Image); stdcall;
  end;

  PD2D1EffectInputDescription = ^TD2D1EffectInputDescription;
  TD2D1EffectInputDescription = record
    effect: ID2D1Effect;
    inputIndex: UINT32;
    inputRectangle: TD2D1RectF;
  end;

  ID2D1GradientStopCollection1 = interface(ID2D1GradientStopCollection)
  ['{ae1572f4-5dd0-4777-998b-9279472ae63b}']
    procedure GetGradientStops1(out gradientStops: PD2D1GradientStop; gradientStopsCount: UINT32); stdcall;
    function GetPreInterpolationSpace: TD2D1ColorSpace; stdcall;
    function GetPostInterpolationSpace: TD2D1ColorSpace; stdcall;
    function GetBufferPrecision: TD2D1BufferPrecision; stdcall;
    function GetColorInterpolationMode: TD2D1ColorInterpolationMode; stdcall;
  end;

  ID2D1ImageBrush = interface(ID2D1Brush)
  ['{fe9e984d-3f95-407c-b5db-cb94d4e8f87c}']
    procedure SetImage(image: ID2D1Image); stdcall;
    procedure SetExtendModeX(extendModeX: TD2D1ExtendMode); stdcall;
    procedure SetExtendModeY(extendModeY: TD2D1ExtendMode); stdcall;
    procedure SetInterpolationMode(interpolationMode: TD2D1InterpolationMode); stdcall;
    procedure SetSourceRectangle(sourceRectangle: TD2D1RectF); stdcall;
    procedure GetImage(out image: ID2D1Image); stdcall;
    function GetExtendModeX: TD2D1ExtendMode; stdcall;
    function GetExtendModeY: TD2D1ExtendMode; stdcall;
    function GetInterpolationMode: TD2D1InterpolationMode; stdcall;
    procedure GetSourceRectangle(out sourceRectangle: TD2D1RectF); stdcall;
  end;

  ID2D1BitmapBrush1 = interface(ID2D1BitmapBrush)
  ['{41343a53-e41a-49a2-91cd-21793bbb62e5}']
    procedure SetInterpolationMode1(interpolationMode: TD2D1InterpolationMode); stdcall;
    function GetInterpolationMode1: TD2D1InterpolationMode; stdcall;
  end;

  ID2D1DeviceContext = interface;
  ID2D1BitmapRenderTarget = interface;

  ID2D1Device = interface(ID2D1Resource)
  ['{47dd575d-ac05-4cdd-8049-9b02cd16f44c}']
    function CreateDeviceContext(options: TD2D1DeviceContextOptions; out deviceContext: ID2D1DeviceContext): HResult; stdcall;
    function CreatePrintControl(wicFactory: IWICImagingFactory; documentTarget: {IPrintDocumentPackageTarget}IUnknown;
        printControlProperties: Pointer{PD2D1_PRINT_CONTROL_PROPERTIES}; out printControl: IUnknown{ID2D1PrintControl}): HResult; stdcall;
    procedure SetMaximumTextureMemory(maximumInBytes: UINT64); stdcall;
    function GetMaximumTextureMemory: UINT64; stdcall;
    procedure ClearResources(millisecondsSinceUse: UINT32 = 0); stdcall;
  end;

  ID2D1RenderTarget = interface(ID2D1Resource)
    [SID_ID2D1RenderTarget]
    // Create a D2D bitmap by copying from memory, or create uninitialized.
    function CreateBitmap(size: D2D1_SIZE_U; srcData: Pointer; pitch: Cardinal;
      const bitmapProperties: TD2D1BitmapProperties;
      out bitmap: ID2D1Bitmap): HResult; stdcall;

//    // Create a D2D bitmap by copying a WIC bitmap.
    function CreateBitmapFromWicBitmap(
      const wicBitmapSource: IWICBitmapSource;
      bitmapProperties: PD2D1BitmapProperties;
      out bitmap: ID2D1Bitmap): HResult; stdcall;

    // Create a D2D bitmap by sharing bits from another resource. The bitmap must be
    // compatible with the render target for the call to succeed.
    // For example, an IWICBitmap can be shared with a software target, or a DXGI
    // surface can be shared with a DXGI render target.
    function CreateSharedBitmap(const riid: TGUID; data: Pointer;
      bitmapProperties: PD2D1BitmapProperties;
      out bitmap: ID2D1Bitmap): HResult; stdcall;

    // Creates a bitmap brush. The bitmap is scaled, rotated, skewed or tiled to fill
    // or pen a geometry.
    function CreateBitmapBrush(const bitmap: ID2D1Bitmap;
      bitmapBrushProperties: PD2D1BitmapBrushProperties;
      brushProperties: PD2D1BrushProperties;
      out bitmapBrush: ID2D1BitmapBrush): HResult; stdcall;

    function CreateSolidColorBrush(const color: D2D1_COLOR_F;
      brushProperties: PD2D1BrushProperties;
      out solidColorBrush: ID2D1SolidColorBrush): HResult; stdcall;

    // A gradient stop collection represents a set of stops in an ideal unit length.
    // This is the source resource for a linear gradient and radial gradient brush.
    function CreateGradientStopCollection(const gradientStops: PD2D1GradientStop;
      gradientStopsCount: UINT; colorInterpolationGamma: TD2D1Gamma;
      extendMode: TD2D1ExtendMode;
      out gradientStopCollection: ID2D1GradientStopCollection): HResult; stdcall;

    function CreateLinearGradientBrush(
      const linearGradientBrushProperties: TD2D1LinearGradientBrushProperties;
      brushProperties: PD2D1BrushProperties;
      gradientStopCollection: ID2D1GradientStopCollection;
      out linearGradientBrush: ID2D1LinearGradientBrush): HResult; stdcall;

    function CreateRadialGradientBrush(
      const radialGradientBrushProperties: TD2D1RadialGradientBrushProperties;
      brushProperties: PD2D1BrushProperties;
      gradientStopCollection: ID2D1GradientStopCollection;
      out radialGradientBrush: ID2D1RadialGradientBrush): HResult; stdcall;

    // Creates a bitmap render target whose bitmap can be used as a source for
    // rendering in the API.
    function CreateCompatibleRenderTarget(desiredSize: PD2D1SizeF;
      desiredPixelSize: PD2D1SizeU; desiredFormat: PD2D1PixelFormat;
      options: TD2D1CompatibleRenderTargetOptions;
      out bitmapRenderTarget: ID2D1BitmapRenderTarget): HResult; stdcall;

    // Creates a layer resource that can be used on any target and which will resize
    // under the covers if necessary.
    function CreateLayer(size: PD2D1SizeF;
      out layer: ID2D1Layer): HResult; stdcall;

    // Create a D2D mesh.
    function CreateMesh(out mesh: ID2D1Mesh): HResult; stdcall;

    procedure DrawLine(point0, point1: TD2DPoint2f;
      const brush: ID2D1Brush; strokeWidth: Single = 1.0;
      const strokeStyle: ID2D1StrokeStyle = nil); stdcall;

    procedure DrawRectangle(const rect: TD2D1RectF; const brush: ID2D1Brush;
      strokeWidth: Single = 1.0; const strokeStyle: ID2D1StrokeStyle = nil); stdcall;

    procedure FillRectangle(const rect: TD2D1RectF; const brush: ID2D1Brush); stdcall;

    procedure DrawRoundedRectangle(const roundedRect: TD2D1RoundedRect;
      const brush: ID2D1Brush; strokeWidth: Single = 1.0;
      const strokeStyle: ID2D1StrokeStyle = nil); stdcall;

    procedure FillRoundedRectangle(const roundedRect: TD2D1RoundedRect;
      const brush: ID2D1Brush); stdcall;

    procedure DrawEllipse(const ellipse: TD2D1Ellipse; const brush: ID2D1Brush;
      strokeWidth: Single = 1.0; const strokeStyle: ID2D1StrokeStyle = nil); stdcall;

    procedure FillEllipse(const ellipse: TD2D1Ellipse; const brush: ID2D1Brush); stdcall;

    procedure DrawGeometry(geometry: ID2D1Geometry; const brush: ID2D1Brush;
      strokeWidth: Single = 1.0; const strokeStyle: ID2D1StrokeStyle = nil); stdcall;

    procedure FillGeometry(const geometry: ID2D1Geometry; const brush: ID2D1Brush;
      const opacityBrush: ID2D1Brush = nil); stdcall;

    // Fill a mesh. Since meshes can only render aliased content, the render target
    // antialiasing mode must be set to aliased.
    procedure FillMesh(const mesh: ID2D1Mesh; const brush: ID2D1Brush); stdcall;

    // Fill using the opacity channel of the supplied bitmap as a mask. The alpha
    // channel of the bitmap is used to represent the coverage of the geometry at each
    // pixel, and this is filled appropriately with the brush. The render target
    // antialiasing mode must be set to aliased.
    procedure FillOpacityMask(opacityMask: ID2D1Bitmap; brush: ID2D1Brush;
      content: TD2D1OpacityMaskContent;
      destinationRectangle: PD2D1RectF = nil;
      sourceRectangle: PD2D1RectF = nil); stdcall;

    procedure DrawBitmap(const bitmap: ID2D1Bitmap;
      destinationRectangle: PD2D1RectF = nil; opacity: Single = 1.0;
      interpolationMode: TD2D1BitmapInterpolationMode = D2D1_BITMAP_INTERPOLATION_MODE_LINEAR;
      sourceRectangle: PD2D1RectF = nil); stdcall;

    // Draws the text within the given layout rectangle and by default also snaps and
    // clips it to the content bounds.
    procedure DrawText(&string: PWCHAR; stringLength: UINT;
      const textFormat: IDWriteTextFormat;
      const layoutRect: D2D1_RECT_F;
      const defaultForegroundBrush: ID2D1Brush;
      options: TD2D1DrawTextOptions = D2D1_DRAW_TEXT_OPTIONS_NONE;
      measuringMode: TDWriteMeasuringMode = DWRITE_MEASURING_MODE_NATURAL);
      stdcall;

    // Draw a snapped text layout object. Since the layout is not subsequently changed,
    // this can be more effecient than DrawText when drawing the same layout repeatedly.
    procedure DrawTextLayout(origin: D2D1_POINT_2F; const textLayout: IDWriteTextLayout;
      const defaultForegroundBrush: ID2D1Brush;
      options: D2D1_DRAW_TEXT_OPTIONS = D2D1_DRAW_TEXT_OPTIONS_NONE); stdcall;

    procedure DrawGlyphRun(baselineOrigin: D2D1_POINT_2F;
      var glyphRun: TDWriteGlyphRun;
      const foregroundBrush: ID2D1Brush;
      measuringMode: TDWriteMeasuringMode = DWRITE_MEASURING_MODE_NATURAL); stdcall;

    procedure SetTransform(const transform: TD2D1Matrix3x2F); stdcall;

    procedure GetTransform(var transform: TD2D1Matrix3x2F); stdcall;

    procedure SetAntialiasMode(antialiasMode: TD2D1AntiAliasMode); stdcall;

    function GetAntialiasMode: TD2D1AntiAliasMode; stdcall;

    procedure SetTextAntialiasMode(
      textAntialiasMode: TD2D1TextAntiAliasMode); stdcall;

    function GetTextAntialiasMode: TD2D1TextAntiAliasMode; stdcall;

    procedure SetTextRenderingParams(
      const textRenderingParams: IDWriteRenderingParams); stdcall;

    // Retrieve the text render parameters. NOTE: If NULL is specified to
    // SetTextRenderingParameters, NULL will be returned.
    procedure GetTextRenderingParams(
      out textRenderingParams: IDWriteRenderingParams); stdcall;

    // Set a tag to correspond to the succeeding primitives. If an error occurs
    // rendering a primtive, the tags can be returned from the Flush or EndDraw call.
    procedure SetTags(tag1: D2D1_TAG; tag2: D2D1_TAG); stdcall;

    // Retrieves the currently set tags. This does not retrieve the tags corresponding
    // to any primitive that is in error.
    procedure GetTags(tag1: PD2D1Tag = nil; tag2: PD2D1Tag = nil); stdcall;

    // Start a layer of drawing calls. The way in which the layer must be resolved is
    // specified first as well as the logical resource that stores the layer
    // parameters. The supplied layer resource might grow if the specified content
    // cannot fit inside it. The layer will grow monitonically on each axis.
    procedure PushLayer(var layerParameters: D2D1_LAYER_PARAMETERS;
      const layer: ID2D1Layer); stdcall;

    // Ends a layer that was defined with particular layer resources.
    procedure PopLayer; stdcall;

    function Flush(tag1: PD2D1Tag = nil; tag2: PD2D1Tag = nil): HResult; stdcall;

    // Gets the current drawing state and saves it into the supplied
    // IDrawingStatckBlock.
    procedure SaveDrawingState(
      var drawingStateBlock: ID2D1DrawingStateBlock); stdcall;

    // Copies the state stored in the block interface.
    procedure RestoreDrawingState(
      const drawingStateBlock: ID2D1DrawingStateBlock); stdcall;

    // Pushes a clip. The clip can be antialiased. The clip must be axis aligned. If
    // the current world transform is not axis preserving, then the bounding box of the
    // transformed clip rect will be used. The clip will remain in effect until a
    // PopAxisAligned clip call is made.
    procedure PushAxisAlignedClip(const clipRect: TD2D1RectF;
      antialiasMode: D2D1_ANTIALIAS_MODE); stdcall;

    procedure PopAxisAlignedClip; stdcall;

    procedure Clear(const clearColor: D2D1_COLOR_F); stdcall;

    // Start drawing on this render target. Draw calls can only be issued between a
    // BeginDraw and EndDraw call.
    procedure BeginDraw; stdcall;

    // Ends drawing on the render target, error results can be retrieved at this time,
    // or when calling flush.
    function EndDraw(tag1: PD2D1Tag = nil;
      tag2: PD2D1Tag = nil): HResult; stdcall;

    procedure GetPixelFormat(out pixelFormat: TD2D1PixelFormat); stdcall;

    // Sets the DPI on the render target. This results in the render target being
    // interpretted to a different scale. Neither DPI can be negative. If zero is
    // specified for both, the system DPI is chosen. If one is zero and the other
    // unspecified, the DPI is not changed.
    procedure SetDpi(dpiX, dpiY: Single); stdcall;

    // Return the current DPI from the target.
    procedure GetDpi(out dpiX, dpiY: Single); stdcall;

    // Returns the size of the render target in DIPs.
    procedure GetSize(out size: TD2D1SizeF); stdcall;

    // Returns the size of the render target in pixels.
    procedure GetPixelSize(out pixelSize: TD2D1SizeU); stdcall;

    // Returns the maximum bitmap and render target size that is guaranteed to be
    // supported by the render target.
    function GetMaximumBitmapSize: UInt32; stdcall;

    // Returns true if the given properties are supported by this render target. The
    // DPI is ignored. NOTE: If the render target type is software, then neither
    // D2D1_FEATURE_LEVEL_9 nor D2D1_FEATURE_LEVEL_10 will be considered to be
    // supported.
    function IsSupported(const renderTargetProperties: TD2D1RenderTargetProperties): BOOL; stdcall;
  end;

  ID2D1BitmapRenderTarget = interface(ID2D1RenderTarget)
    [SID_ID2D1BitmapRenderTarget]
    function GetBitmap(out bitmap: ID2D1Bitmap): HResult; stdcall;
  end;

  ID2D1DeviceContext = interface(ID2D1RenderTarget)
  ['{e8f7fe7a-191c-466d-ad95-975678bda998}']
    function CreateBitmap(size: TD2D1SizeU; sourceData: Pointer; pitch: UINT32;
      bitmapProperties: PD2D1BitmapProperties1; out bitmap: ID2D1Bitmap1): HResult; stdcall;
    function CreateBitmapFromWicBitmap(wicBitmapSource: IWICBitmapSource;
      bitmapProperties: PD2D1BitmapProperties1; out bitmap: ID2D1Bitmap1): HResult; stdcall;
    function CreateColorContext(space: TD2D1ColorSpace; profile: PBYTE;
      profileSize: UINT32; out colorContext: ID2D1ColorContext): HResult; stdcall;
    function CreateColorContextFromFilename(filename: PWideChar; out colorContext: ID2D1ColorContext): HResult; stdcall;
    function CreateColorContextFromWicColorContext(wicColorContext: IWICColorContext; out colorContext: ID2D1ColorContext): HResult; stdcall;
    function CreateBitmapFromDxgiSurface(surface: IDXGISurface;
      const bitmapProperties: TD2D1BitmapProperties1; out bitmap: ID2D1Bitmap1): HResult; stdcall;
    function CreateEffect(const effectId: TGUID; out effect: ID2D1Effect): HResult; stdcall;
    function CreateGradientStopCollection2(straightAlphaGradientStops: PD2D1GradientStop;
      straightAlphaGradientStopsCount: UINT32; preInterpolationSpace: TD2D1ColorSpace;
      postInterpolationSpace: TD2D1ColorSpace; bufferPrecision: TD2D1BufferPrecision;
      extendMode: TD2D1ExtendMode; colorInterpolationMode: TD2D1ColorInterpolationMode;
      out gradientStopCollection1: ID2D1GradientStopCollection1): HResult; stdcall;
    function CreateImageBrush(image: ID2D1Image; imageBrushProperties: PD2D1ImageBrushProperties;
      brushProperties: PD2D1BrushProperties; out imageBrush: ID2D1ImageBrush): HResult; stdcall;
    function CreateBitmapBrush(bitmap: ID2D1Bitmap; bitmapBrushProperties: PD2D1BitmapBrushProperties1;
      brushProperties: PD2D1BrushProperties; out bitmapBrush: ID2D1BitmapBrush1): HResult; stdcall;
    function CreateCommandList(out commandList: IUnknown{ID2D1CommandList}): HResult; stdcall;
    function IsDxgiFormatSupported(format: DXGI_FORMAT): LongBool; stdcall;
    function IsBufferPrecisionSupported(bufferPrecision: TD2D1BufferPrecision): LongBool; stdcall;
    function GetImageLocalBounds(image: ID2D1Image; out localBounds: TD2D1RectF): HResult; stdcall;
    function GetImageWorldBounds(image: ID2D1Image; out worldBounds: TD2D1RectF): HResult; stdcall;
    function GetGlyphRunWorldBounds(baselineOrigin: TD2D1Point2F; glyphRun: PDwriteGlyphRun;
      measuringMode: TDWriteMeasuringMode; out bounds: TD2D1RectF): HResult; stdcall;
    procedure GetDevice(out device: ID2D1Device); stdcall;
    procedure SetTarget(image: ID2D1Image); stdcall;
    procedure GetTarget(out image: ID2D1Image); stdcall;
    procedure SetRenderingControls(renderingControls: PD2D1RenderingControls); stdcall;
    procedure GetRenderingControls(out renderingControls: TD2D1RenderingControls); stdcall;
    procedure SetPrimitiveBlend(primitiveBlend: TD2D1PrimitiveBlend); stdcall;
    function GetPrimitiveBlend: TD2D1PrimitiveBlend; stdcall;
    procedure SetUnitMode(unitMode: TD2D1UnitMode); stdcall;
    function GetUnitMode: TD2D1UnitMode; stdcall;
    procedure DrawGlyphRun(baselineOrigin: TD2D1Point2F; glyphRun: PDwriteGlyphRun; glyphRunDescription: PDwriteGlyphRunDescription;
      foregroundBrush: ID2D1Brush; measuringMode: TDWriteMeasuringMode = DWRITE_MEASURING_MODE_NATURAL); stdcall;
    procedure DrawImage(image: ID2D1Image; targetOffset: PD2D1Point2F = nil; imageRectangle: PD2D1RectF = nil;
      interpolationMode: TD2D1InterpolationMode = D2D1_INTERPOLATION_MODE_LINEAR;
      compositeMode: TD2D1CompositeMode = D2D1_COMPOSITE_MODE_SOURCE_OVER); stdcall;
    procedure DrawGdiMetafile(gdiMetafile: IUnknown{ID2D1GdiMetafile}; targetOffset: PD2D1Point2F = nil); stdcall;
    procedure DrawBitmap(bitmap: ID2D1Bitmap; destinationRectangle: PD2D1RectF; opacity: single;
      interpolationMode: TD2D1InterpolationMode; sourceRectangle: PD2D1RectF = nil;
      perspectiveTransform: Pointer{PD2D1_MATRIX_4X4_F} = nil); stdcall;
    procedure PushLayer(layerParameters: PD2D1LayerParameters1; layer: ID2D1Layer); stdcall;
    function InvalidateEffectInputRectangle(effect: ID2D1Effect; input: UINT32; inputRectangle: PD2D1RectF): HResult; stdcall;
    function GetEffectInvalidRectangleCount(effect: ID2D1Effect; out rectangleCount: UINT32): HResult; stdcall;
    function GetEffectInvalidRectangles(effect: ID2D1Effect; out rectangles: PD2D1RectF; rectanglesCount: UINT32): HResult; stdcall;
    function GetEffectRequiredInputRectangles(renderEffect: ID2D1Effect; renderImageRectangle: PD2D1RectF;
      inputDescriptions: PD2D1EffectInputDescription; out requiredInputRects: PD2D1RectF; inputCount: UINT32): HResult; stdcall;
    procedure FillOpacityMask(opacityMask: ID2D1Bitmap; brush: ID2D1Brush; destinationRectangle: PD2D1RectF = nil;
      sourceRectangle: PD2D1RectF = nil); stdcall;
  end;

  ID2D1StrokeStyle1 = interface(ID2D1StrokeStyle)
  ['{10a72a66-e91c-43f4-993f-ddf4b82b0b4a}']
  function GetStrokeTransformType: TD2D1StrokeTransformType; stdcall;
  end;

  ID2D1PathGeometry1 = interface(ID2D1PathGeometry)
  ['{62baa2d2-ab54-41b7-b872-787e0106a421}']
    function ComputePointAndSegmentAtLength(length: single; startSegment: UINT32; worldTransform: PD2D1Matrix3x2F;
      flatteningTolerance: single; out pointDescription: TD2D1PointDescription): HResult; stdcall;
  end;

  ID2D1DrawingStateBlock1 = interface(ID2D1DrawingStateBlock)
  ['{689f1f85-c72e-4e33-8f19-85754efd5ace}']
    procedure GetDescription(out stateDescription: TD2D1DrawingStateDescription1); stdcall;
    procedure SetDescription(stateDescription: PD2D1DrawingStateDescription1); stdcall;
  end;

  TD2D1EffectFactoryCallback = function(out effectImpl: IUnknown): HResult; stdcall; // callback

  ID2D1Factory1 = interface(ID2D1Factory)
  [SID_ID2D1Factory1]
    function CreateDevice(dxgiDevice: IDXGIDevice; out d2dDevice: ID2D1Device): HResult; stdcall;
    function CreateStrokeStyle(strokeStyleProperties: PD2D1StrokeStyleProperties1;
      dashes: PSingle; dashesCount: UINT32; out strokeStyle: ID2D1StrokeStyle1): HResult; stdcall;
    function CreatePathGeometry(out pathGeometry: ID2D1PathGeometry1): HResult; stdcall;
    function CreateDrawingStateBlock(drawingStateDescription: PD2D1DrawingStateDescription1;
      textRenderingParams: IDWriteRenderingParams; out drawingStateBlock: ID2D1DrawingStateBlock1): HResult; stdcall;
    function CreateGdiMetafile(metafileStream: IStream; out metafile: IUnknown{ID2D1GdiMetafile}): HResult; stdcall;
    function RegisterEffectFromStream(classId: TGUID; propertyXml: IStream; bindings: PD2D1PropertyBinding;
      bindingsCount: UINT32; effectFactory: TD2D1EffectFactoryCallback): HResult; stdcall;
    function RegisterEffectFromString(classId: TGUID; propertyXml: PWideChar; bindings: PD2D1PropertyBinding;
      bindingsCount: UINT32; effectFactory: TD2D1EffectFactoryCallback): HResult; stdcall;
    function UnregisterEffect(classId: TGUID): HResult; stdcall;
    function GetRegisteredEffects(out effects: PGUID; effectsCount: UINT32;
      out effectsReturned: UINT32; out effectsRegistered: UINT32): HResult; stdcall;
    function GetEffectProperties(effectId: TGUID; out properties: ID2D1Properties): HResult; stdcall;
  end;

// ---------------------------------------------------------------------------------------------------------------------
// Direct2D Effects
// ---------------------------------------------------------------------------------------------------------------------

const
  CLSID_D2D1ArithmeticComposite: TGUID = '{fc151437-049a-4784-a24a-f1c4daf20987}';
  CLSID_D2D1Atlas: TGUID = '{913e2be4-fdcf-4fe2-a5f0-2454f14ff408}';
  CLSID_D2D1BitmapSource: TGUID = '{5fb6c24d-c6dd-4231-9404-50f4d5c3252d}';
  CLSID_D2D1Blend: TGUID = '{81c5b77b-13f8-4cdd-ad20-c890547ac65d}';
  CLSID_D2D1Border: TGUID = '{2A2D49C0-4ACF-43c7-8C6A-7C4A27874D27}';
  CLSID_D2D1Brightness: TGUID = '{8cea8d1e-77b0-4986-b3b9-2f0c0eae7887}';
  CLSID_D2D1ColorManagement: TGUID = '{1A28524C-FDD6-4AA4-AE8F-837EB8267B37}';
  CLSID_D2D1ColorMatrix: TGUID = '{921F03D6-641C-47DF-852D-B4BB6153AE11}';
  CLSID_D2D1Composite: TGUID = '{48fc9f51-f6ac-48f1-8b58-3b28ac46f76d}';
  CLSID_D2D1ConvolveMatrix: TGUID = '{407f8c08-5533-4331-a341-23cc3877843e}';
  CLSID_D2D1Crop: TGUID = '{E23F7110-0E9A-4324-AF47-6A2C0C46F35B}';
  CLSID_D2D1DirectionalBlur: TGUID = '{174319a6-58e9-49b2-bb63-caf2c811a3db}';
  CLSID_D2D1DiscreteTransfer: TGUID = '{90866fcd-488e-454b-af06-e5041b66c36c}';
  CLSID_D2D1DisplacementMap: TGUID = '{edc48364-0417-4111-9450-43845fa9f890}';
  CLSID_D2D1DistantDiffuse: TGUID = '{3e7efd62-a32d-46d4-a83c-5278889ac954}';
  CLSID_D2D1DistantSpecular: TGUID = '{428c1ee5-77b8-4450-8ab5-72219c21abda}';
  CLSID_D2D1DpiCompensation: TGUID = '{6c26c5c7-34e0-46fc-9cfd-e5823706e228}';
  CLSID_D2D1Flood: TGUID = '{61c23c20-ae69-4d8e-94cf-50078df638f2}';
  CLSID_D2D1GammaTransfer: TGUID = '{409444c4-c419-41a0-b0c1-8cd0c0a18e42}';
  CLSID_D2D1GaussianBlur: TGUID = '{1feb6d69-2fe6-4ac9-8c58-1d7f93e7a6a5}';
  CLSID_D2D1Histogram: TGUID = '{881db7d0-f7ee-4d4d-a6d2-4697acc66ee8}';
  CLSID_D2D1HueRotation: TGUID = '{0f4458ec-4b32-491b-9e85-bd73f44d3eb6}';
  CLSID_D2D1LinearTransfer: TGUID = '{ad47c8fd-63ef-4acc-9b51-67979c036c06}';
  CLSID_D2D1LuminanceToAlpha: TGUID = '{41251ab7-0beb-46f8-9da7-59e93fcce5de}';
  CLSID_D2D1Morphology: TGUID = '{eae6c40d-626a-4c2d-bfcb-391001abe202}';
  CLSID_D2D1OpacityMetadata: TGUID = '{6c53006a-4450-4199-aa5b-ad1656fece5e}';
  CLSID_D2D1PointDiffuse: TGUID = '{b9e303c3-c08c-4f91-8b7b-38656bc48c20}';
  CLSID_D2D1PointSpecular: TGUID = '{09c3ca26-3ae2-4f09-9ebc-ed3865d53f22}';
  CLSID_D2D1Premultiply: TGUID = '{06eab419-deed-4018-80d2-3e1d471adeb2}';
  CLSID_D2D1Saturation: TGUID = '{5cb2d9cf-327d-459f-a0ce-40c0b2086bf7}';
  CLSID_D2D1Scale: TGUID = '{9daf9369-3846-4d0e-a44e-0c607934a5d7}';
  CLSID_D2D1Shadow: TGUID = '{C67EA361-1863-4e69-89DB-695D3E9A5B6B}';
  CLSID_D2D1SpotDiffuse: TGUID = '{818a1105-7932-44f4-aa86-08ae7b2f2c93}';
  CLSID_D2D1SpotSpecular: TGUID = '{edae421e-7654-4a37-9db8-71acc1beb3c1}';
  CLSID_D2D1TableTransfer: TGUID = '{5bf818c3-5e43-48cb-b631-868396d6a1d4}';
  CLSID_D2D1Tile: TGUID = '{B0784138-3B76-4bc5-B13B-0FA2AD02659F}';
  CLSID_D2D1Turbulence: TGUID = '{CF2BB6AE-889A-4ad7-BA29-A2FD732C9FC9}';
  CLSID_D2D1UnPremultiply: TGUID = '{fb9ac489-ad8d-41ed-9999-bb6347d110f7}';
  CLSID_D2D12DAffineTransform: TGUID = '{6AA97485-6354-4cfc-908C-E4A74F62C96C}';
  CLSID_D2D13DPerspectiveTransform: TGUID = '{C2844D0B-3D86-46e7-85BA-526C9240F3FB}';
  CLSID_D2D13DTransform: TGUID = '{e8467b04-ec61-4b8a-b5de-d4d73debea5a}';

  D2D1_GAUSSIANBLUR_PROP_STANDARD_DEVIATION = 0;
  D2D1_GAUSSIANBLUR_PROP_OPTIMIZATION = 1;
  D2D1_GAUSSIANBLUR_PROP_BORDER_MODE = 2;

  D2D1_GAUSSIANBLUR_OPTIMIZATION_SPEED = 0;
  D2D1_GAUSSIANBLUR_OPTIMIZATION_BALANCED = 1;
  D2D1_GAUSSIANBLUR_OPTIMIZATION_QUALITY = 2;

  D2D1_DIRECTIONALBLUR_PROP_STANDARD_DEVIATION = 0;
  D2D1_DIRECTIONALBLUR_PROP_ANGLE = 1;
  D2D1_DIRECTIONALBLUR_PROP_OPTIMIZATION = 2;
  D2D1_DIRECTIONALBLUR_PROP_BORDER_MODE = 3;

  D2D1_DIRECTIONALBLUR_OPTIMIZATION_SPEED = 0;
  D2D1_DIRECTIONALBLUR_OPTIMIZATION_BALANCED = 1;
  D2D1_DIRECTIONALBLUR_OPTIMIZATION_QUALITY = 2;

  D2D1_SHADOW_PROP_BLUR_STANDARD_DEVIATION = 0;
  D2D1_SHADOW_PROP_COLOR = 1;
  D2D1_SHADOW_PROP_OPTIMIZATION = 2;

  D2D1_SHADOW_OPTIMIZATION_SPEED = 0;
  D2D1_SHADOW_OPTIMIZATION_BALANCED = 1;
  D2D1_SHADOW_OPTIMIZATION_QUALITY = 2;

  D2D1_BLEND_MODE_MULTIPLY = 0;
  D2D1_BLEND_MODE_SCREEN = 1;
  D2D1_BLEND_MODE_DARKEN = 2;
  D2D1_BLEND_MODE_LIGHTEN = 3;
  D2D1_BLEND_MODE_DISSOLVE = 4;
  D2D1_BLEND_MODE_COLOR_BURN = 5;
  D2D1_BLEND_MODE_LINEAR_BURN = 6;
  D2D1_BLEND_MODE_DARKER_COLOR = 7;
  D2D1_BLEND_MODE_LIGHTER_COLOR = 8;
  D2D1_BLEND_MODE_COLOR_DODGE = 9;
  D2D1_BLEND_MODE_LINEAR_DODGE = 10;
  D2D1_BLEND_MODE_OVERLAY = 11;
  D2D1_BLEND_MODE_SOFT_LIGHT = 12;
  D2D1_BLEND_MODE_HARD_LIGHT = 13;
  D2D1_BLEND_MODE_VIVID_LIGHT = 14;
  D2D1_BLEND_MODE_LINEAR_LIGHT = 15;
  D2D1_BLEND_MODE_PIN_LIGHT = 16;
  D2D1_BLEND_MODE_HARD_MIX = 17;
  D2D1_BLEND_MODE_DIFFERENCE = 18;
  D2D1_BLEND_MODE_EXCLUSION = 19;
  D2D1_BLEND_MODE_HUE = 20;
  D2D1_BLEND_MODE_SATURATION = 21;
  D2D1_BLEND_MODE_COLOR = 22;
  D2D1_BLEND_MODE_LUMINOSITY = 23;
  D2D1_BLEND_MODE_SUBTRACT = 24;
  D2D1_BLEND_MODE_DIVISION = 25;

  D2D1_SATURATION_PROP_SATURATION = 0;

  D2D1_HUEROTATION_PROP_ANGLE = 0;

  D2D1_COLORMATRIX_PROP_COLOR_MATRIX = 0;
  D2D1_COLORMATRIX_PROP_ALPHA_MODE = 1;
  D2D1_COLORMATRIX_PROP_CLAMP_OUTPUT = 2;

  D2D1_COLORMATRIX_ALPHA_MODE_PREMULTIPLIED = 1;
  D2D1_COLORMATRIX_ALPHA_MODE_STRAIGHT = 2;

// ---------------------------------------------------------------------------------------------------------------------
// Direct3D References
// ---------------------------------------------------------------------------------------------------------------------

const
  D3D11lib = 'd3d11.dll';

  D3D11_CREATE_DEVICE_SINGLETHREADED = $1;
  D3D11_CREATE_DEVICE_DEBUG = $2;
  D3D11_CREATE_DEVICE_SWITCH_TO_REF = $4;
  D3D11_CREATE_DEVICE_PREVENT_INTERNAL_THREADING_OPTIMIZATIONS = $8;
  D3D11_CREATE_DEVICE_BGRA_SUPPORT = $20;
  D3D11_CREATE_DEVICE_DEBUGGABLE = $40;
  D3D11_CREATE_DEVICE_PREVENT_ALTERING_LAYER_SETTINGS_FROM_REGISTRY = $80;
  D3D11_CREATE_DEVICE_DISABLE_GPU_TIMEOUT = $100;
  D3D11_CREATE_DEVICE_VIDEO_SUPPORT = $800;

  D3D11_BIND_VERTEX_BUFFER = $1;
  D3D11_BIND_INDEX_BUFFER = $2;
  D3D11_BIND_CONSTANT_BUFFER = $4;
  D3D11_BIND_SHADER_RESOURCE = $8;
  D3D11_BIND_STREAM_OUTPUT = $10;
  D3D11_BIND_RENDER_TARGET = $20;
  D3D11_BIND_DEPTH_STENCIL = $40;
  D3D11_BIND_UNORDERED_ACCESS = $80;
  D3D11_BIND_DECODER = $200;
  D3D11_BIND_VIDEO_ENCODER = $400;

  D3D11_RESOURCE_MISC_GENERATE_MIPS = $1;
  D3D11_RESOURCE_MISC_SHARED = $2;
  D3D11_RESOURCE_MISC_TEXTURECUBE = $4;
  D3D11_RESOURCE_MISC_DRAWINDIRECT_ARGS = $10;
  D3D11_RESOURCE_MISC_BUFFER_ALLOW_RAW_VIEWS = $20;
  D3D11_RESOURCE_MISC_BUFFER_STRUCTURED = $40;
  D3D11_RESOURCE_MISC_RESOURCE_CLAMP = $80;
  D3D11_RESOURCE_MISC_SHARED_KEYEDMUTEX = $100;
  D3D11_RESOURCE_MISC_GDI_COMPATIBLE = $200;
  D3D11_RESOURCE_MISC_SHARED_NTHANDLE = $800;
  D3D11_RESOURCE_MISC_RESTRICTED_CONTENT = $1000;
  D3D11_RESOURCE_MISC_RESTRICT_SHARED_RESOURCE = $2000;
  D3D11_RESOURCE_MISC_RESTRICT_SHARED_RESOURCE_DRIVER = $4000;
  D3D11_RESOURCE_MISC_GUARDED = $8000;
  D3D11_RESOURCE_MISC_TILE_POOL = $20000;
  D3D11_RESOURCE_MISC_TILED = $40000;

  D3D11_SDK_VERSION = (7);

  SID_ID3D11DeviceContext = '{c0bfa96c-e089-44fb-8eaf-26f8796190da}';
  IID_ID3D11DeviceContext: TGUID = SID_ID3D11DeviceContext;

  SID_ID3D11DeviceChild = '{1841e5c8-16b0-489b-bcc8-44cfb0d5deae}';
  IID_ID3D11DeviceChild: TGUID = SID_ID3D11DeviceChild;

  SID_ID3D11Device = '{db6f6ddb-ac77-4e88-8253-819df9bbf140}';
  IID_ID3D11Device: TGUID = SID_ID3D11Device;

  SID_ID3D11PixelShader = '{ea82e40d-51dc-4f33-93d4-db7c9125ae8c}';
  IID_ID3D11PixelShader: TGUID = SID_ID3D11PixelShader;

type
  TD3DDriveType = (
    D3D_DRIVER_TYPE_UNKNOWN = 0,
    D3D_DRIVER_TYPE_HARDWARE = 1,
    D3D_DRIVER_TYPE_REFERENCE = 2,
    D3D_DRIVER_TYPE_NULL = 3,
    D3D_DRIVER_TYPE_SOFTWARE = 4,
    D3D_DRIVER_TYPE_WARP = 5
  );

  PD3DFeatureLevel = ^TD3DFeatureLevel;
  TD3DFeatureLevel = (
    D3D_FEATURE_LEVEL_9_1 = $9100,
    D3D_FEATURE_LEVEL_9_2 = $9200,
    D3D_FEATURE_LEVEL_9_3 = $9300,
    D3D_FEATURE_LEVEL_10_0 = $a000,
    D3D_FEATURE_LEVEL_10_1 = $a100,
    D3D_FEATURE_LEVEL_11_0 = $b000,
    D3D_FEATURE_LEVEL_11_1 = $b100,
    D3D_FEATURE_LEVEL_12_0 = $c000,
    D3D_FEATURE_LEVEL_12_1 = $c100
  );

  TD3D11_RESOURCE_DIMENSION = (
    D3D11_RESOURCE_DIMENSION_UNKNOWN = 0,
    D3D11_RESOURCE_DIMENSION_BUFFER = 1,
    D3D11_RESOURCE_DIMENSION_TEXTURE1D = 2,
    D3D11_RESOURCE_DIMENSION_TEXTURE2D = 3,
    D3D11_RESOURCE_DIMENSION_TEXTURE3D = 4
  );

  TD3D11_MAP = (
    D3D11_MAP_READ = 1,
    D3D11_MAP_WRITE = 2,
    D3D11_MAP_READ_WRITE = 3,
    D3D11_MAP_WRITE_DISCARD = 4,
    D3D11_MAP_WRITE_NO_OVERWRITE = 5
  );

  TD3D11_USAGE = (
    D3D11_USAGE_DEFAULT = 0,
    D3D11_USAGE_IMMUTABLE = 1,
    D3D11_USAGE_DYNAMIC = 2,
    D3D11_USAGE_STAGING = 3
  );

  TD3D_PRIMITIVE_TOPOLOGY =
  (
    D3D_PRIMITIVE_TOPOLOGY_UNDEFINED = 0,
    D3D_PRIMITIVE_TOPOLOGY_POINTLIST = 1,
    D3D_PRIMITIVE_TOPOLOGY_LINELIST = 2,
    D3D_PRIMITIVE_TOPOLOGY_LINESTRIP = 3,
    D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST = 4,
    D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP = 5,
    D3D_PRIMITIVE_TOPOLOGY_LINELIST_ADJ = 10,
    D3D_PRIMITIVE_TOPOLOGY_LINESTRIP_ADJ = 11,
    D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST_ADJ = 12,
    D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP_ADJ = 13,
    D3D_PRIMITIVE_TOPOLOGY_1_CONTROL_POINT_PATCHLIST = 33,
    D3D_PRIMITIVE_TOPOLOGY_2_CONTROL_POINT_PATCHLIST = 34,
    D3D_PRIMITIVE_TOPOLOGY_3_CONTROL_POINT_PATCHLIST = 35,
    D3D_PRIMITIVE_TOPOLOGY_4_CONTROL_POINT_PATCHLIST = 36,
    D3D_PRIMITIVE_TOPOLOGY_5_CONTROL_POINT_PATCHLIST = 37,
    D3D_PRIMITIVE_TOPOLOGY_6_CONTROL_POINT_PATCHLIST = 38,
    D3D_PRIMITIVE_TOPOLOGY_7_CONTROL_POINT_PATCHLIST = 39,
    D3D_PRIMITIVE_TOPOLOGY_8_CONTROL_POINT_PATCHLIST = 40,
    D3D_PRIMITIVE_TOPOLOGY_9_CONTROL_POINT_PATCHLIST = 41,
    D3D_PRIMITIVE_TOPOLOGY_10_CONTROL_POINT_PATCHLIST = 42,
    D3D_PRIMITIVE_TOPOLOGY_11_CONTROL_POINT_PATCHLIST = 43,
    D3D_PRIMITIVE_TOPOLOGY_12_CONTROL_POINT_PATCHLIST = 44,
    D3D_PRIMITIVE_TOPOLOGY_13_CONTROL_POINT_PATCHLIST = 45,
    D3D_PRIMITIVE_TOPOLOGY_14_CONTROL_POINT_PATCHLIST = 46,
    D3D_PRIMITIVE_TOPOLOGY_15_CONTROL_POINT_PATCHLIST = 47,
    D3D_PRIMITIVE_TOPOLOGY_16_CONTROL_POINT_PATCHLIST = 48,
    D3D_PRIMITIVE_TOPOLOGY_17_CONTROL_POINT_PATCHLIST = 49,
    D3D_PRIMITIVE_TOPOLOGY_18_CONTROL_POINT_PATCHLIST = 50,
    D3D_PRIMITIVE_TOPOLOGY_19_CONTROL_POINT_PATCHLIST = 51,
    D3D_PRIMITIVE_TOPOLOGY_20_CONTROL_POINT_PATCHLIST = 52,
    D3D_PRIMITIVE_TOPOLOGY_21_CONTROL_POINT_PATCHLIST = 53,
    D3D_PRIMITIVE_TOPOLOGY_22_CONTROL_POINT_PATCHLIST = 54,
    D3D_PRIMITIVE_TOPOLOGY_23_CONTROL_POINT_PATCHLIST = 55,
    D3D_PRIMITIVE_TOPOLOGY_24_CONTROL_POINT_PATCHLIST = 56,
    D3D_PRIMITIVE_TOPOLOGY_25_CONTROL_POINT_PATCHLIST = 57,
    D3D_PRIMITIVE_TOPOLOGY_26_CONTROL_POINT_PATCHLIST = 58,
    D3D_PRIMITIVE_TOPOLOGY_27_CONTROL_POINT_PATCHLIST = 59,
    D3D_PRIMITIVE_TOPOLOGY_28_CONTROL_POINT_PATCHLIST = 60,
    D3D_PRIMITIVE_TOPOLOGY_29_CONTROL_POINT_PATCHLIST = 61,
    D3D_PRIMITIVE_TOPOLOGY_30_CONTROL_POINT_PATCHLIST = 62,
    D3D_PRIMITIVE_TOPOLOGY_31_CONTROL_POINT_PATCHLIST = 63,
    D3D_PRIMITIVE_TOPOLOGY_32_CONTROL_POINT_PATCHLIST = 64,
    D3D10_PRIMITIVE_TOPOLOGY_UNDEFINED = D3D_PRIMITIVE_TOPOLOGY_UNDEFINED,
    D3D10_PRIMITIVE_TOPOLOGY_POINTLIST = D3D_PRIMITIVE_TOPOLOGY_POINTLIST,
    D3D10_PRIMITIVE_TOPOLOGY_LINELIST = D3D_PRIMITIVE_TOPOLOGY_LINELIST,
    D3D10_PRIMITIVE_TOPOLOGY_LINESTRIP = D3D_PRIMITIVE_TOPOLOGY_LINESTRIP,
    D3D10_PRIMITIVE_TOPOLOGY_TRIANGLELIST = D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST,
    D3D10_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP = D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP,
    D3D10_PRIMITIVE_TOPOLOGY_LINELIST_ADJ = D3D_PRIMITIVE_TOPOLOGY_LINELIST_ADJ,
    D3D10_PRIMITIVE_TOPOLOGY_LINESTRIP_ADJ = D3D_PRIMITIVE_TOPOLOGY_LINESTRIP_ADJ,
    D3D10_PRIMITIVE_TOPOLOGY_TRIANGLELIST_ADJ = D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST_ADJ,
    D3D10_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP_ADJ = D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP_ADJ,
    D3D11_PRIMITIVE_TOPOLOGY_UNDEFINED = D3D_PRIMITIVE_TOPOLOGY_UNDEFINED,
    D3D11_PRIMITIVE_TOPOLOGY_POINTLIST = D3D_PRIMITIVE_TOPOLOGY_POINTLIST,
    D3D11_PRIMITIVE_TOPOLOGY_LINELIST = D3D_PRIMITIVE_TOPOLOGY_LINELIST,
    D3D11_PRIMITIVE_TOPOLOGY_LINESTRIP = D3D_PRIMITIVE_TOPOLOGY_LINESTRIP,
    D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST = D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST,
    D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP = D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP,
    D3D11_PRIMITIVE_TOPOLOGY_LINELIST_ADJ = D3D_PRIMITIVE_TOPOLOGY_LINELIST_ADJ,
    D3D11_PRIMITIVE_TOPOLOGY_LINESTRIP_ADJ = D3D_PRIMITIVE_TOPOLOGY_LINESTRIP_ADJ,
    D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST_ADJ = D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST_ADJ,
    D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP_ADJ = D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP_ADJ,
    D3D11_PRIMITIVE_TOPOLOGY_1_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_1_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_2_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_2_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_3_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_3_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_4_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_4_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_5_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_5_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_6_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_6_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_7_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_7_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_8_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_8_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_9_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_9_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_10_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_10_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_11_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_11_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_12_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_12_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_13_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_13_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_14_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_14_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_15_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_15_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_16_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_16_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_17_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_17_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_18_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_18_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_19_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_19_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_20_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_20_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_21_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_21_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_22_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_22_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_23_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_23_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_24_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_24_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_25_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_25_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_26_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_26_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_27_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_27_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_28_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_28_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_29_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_29_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_30_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_30_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_31_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_31_CONTROL_POINT_PATCHLIST,
    D3D11_PRIMITIVE_TOPOLOGY_32_CONTROL_POINT_PATCHLIST = D3D_PRIMITIVE_TOPOLOGY_32_CONTROL_POINT_PATCHLIST
  );

  TD3D11_DEVICE_CONTEXT_TYPE = (
    D3D11_DEVICE_CONTEXT_IMMEDIATE = 0,
    D3D11_DEVICE_CONTEXT_DEFERRED = 1
  );

  PD3D11ViewPort = Pointer;
  PD3D11Rect = Pointer;

  PID3D11ClassInstance = Pointer;
  PID3D11RenderTargetView = Pointer;
  PID3D11SamplerState = Pointer;
  PD3D11SubResourceData = Pointer;

  ID3D11SamplerState = IUnknown;

  ID3D11ShaderResourceView = IUnknown;
  PID3D11ShaderResourceView = ^ID3D11ShaderResourceView;

  ID3D11DepthStencilView = IUnknown;
  ID3D11UnorderedAccessView = IUnknown;
  PID3D11UnorderedAccessView = ^ID3D11UnorderedAccessView;

  TUINTArray4 = array [0..3] of UINT;
  TFloatArray4 = array [0..3] of single;
  TFloatArray3 = array [0..2] of single;
  TFloatArray2 = array [0..1] of single;

  PFloatArray4 = ^TFloatArray4;
  PFloatArray3 = ^TFloatArray3;
  PFloatArray2 = ^TFloatArray2;

  { TD3D11MappedSubResource }

  PD3D11MappedSubResource = ^TD3D11MappedSubResource;
  TD3D11MappedSubResource = record
    pData: Pointer;
    RowPitch: UINT;
    DepthPitch: UINT;
  end;

  { TD3D11Box }

  PD3D11Box = ^TD3D11Box;
  TD3D11Box = record
    left: UINT;
    top: UINT;
    front: UINT;
    right: UINT;
    bottom: UINT;
    back: UINT;

    class function Create(const ALeft, ATop, ARight, ABottom: LongInt; AFront: LongInt = 0; ABack: LongInt = 1): TD3D11Box; overload; static;
    class function Create(const ARect: TRect): TD3D11Box; overload; static;
    class operator Equal(const A, B: TD3D11Box): LongBool;
    class operator NotEqual(const A, B: TD3D11Box): LongBool;
  end;


  { ID3D11Device }


  ID3D11Device = interface;

  { ID3D11DeviceChild }

  ID3D11DeviceChild = interface(IUnknown)
  [SID_ID3D11DeviceChild]
    procedure GetDevice(out ppDevice: ID3D11Device); stdcall;
    function GetPrivateData(guid: TGUID; var pDataSize: UINT; out pData: Pointer): HResult; stdcall;
    function SetPrivateData(guid: TGUID; DataSize: UINT; pData: Pointer): HResult; stdcall;
    function SetPrivateDataInterface(guid: TGUID; pData: IUnknown): HResult; stdcall;
  end;

  { ID3D11PixelShader }

  ID3D11PixelShader = interface(ID3D11DeviceChild)
  [SID_ID3D11PixelShader]
  end;

  { ID3D11VertexShader }

  ID3D11VertexShader = interface(ID3D11DeviceChild)
  ['{3b301d64-d678-4289-8897-22f8928b72f3}']
  end;

  { ID3D11Resource }

  PID3D11Resource = ^ID3D11Resource;
  ID3D11Resource = interface(ID3D11DeviceChild)
  ['{dc8e63f3-d12b-4952-b47b-5e45026a862d}']
    procedure GetType(out pResourceDimension: TD3D11_RESOURCE_DIMENSION); stdcall;
    procedure SetEvictionPriority(EvictionPriority: UINT); stdcall;
    function GetEvictionPriority: UINT; stdcall;
  end;

  { TD3D11BufferDesc }

  PD3D11BufferDesc = ^TD3D11BufferDesc;
  TD3D11BufferDesc = record
    ByteWidth: UINT;
    Usage: TD3D11_USAGE;
    BindFlags: UINT;
    CPUAccessFlags: UINT;
    MiscFlags: UINT;
    StructureByteStride: UINT;

    procedure Init(AByteWidth: UINT; ABindFlags: UINT; AUsage: TD3D11_USAGE = D3D11_USAGE_DEFAULT;
      ACPUAccessFlags: UINT = 0; AMiscFlags: UINT = 0; AStructureByteStride: UINT = 0);
  end;

  { TD3D11Texture2DDesc }

  TD3D11Texture2DDesc = record
    Width: UINT;
    Height: UINT;
    MipLevels: UINT;
    ArraySize: UINT;
    Format: DXGI_FORMAT;
    SampleDesc: TDXGISampleDesc;
    Usage: TD3D11_USAGE;
    BindFlags: UINT;
    CPUAccessFlags: UINT;
    MiscFlags: UINT;
  end;

  { ID3D11Buffer }

  PID3D11Buffer = ^ID3D11Buffer;
  ID3D11Buffer = interface(ID3D11Resource)
  ['{48570b85-d1ee-4fcd-a250-eb350722b037}']
    procedure GetDesc(out pDesc: TD3D11BufferDesc); stdcall;
  end;

  { ID3D11Texture2D }

  ID3D11Texture2D = interface(ID3D11Resource)
  ['{6f15aaf2-d208-4e89-9ab4-489535d34f9c}']
    procedure GetDesc(out pDesc: TD3D11Texture2DDesc); stdcall;
  end;

  { ID3D11InputLayout }

  ID3D11InputLayout = interface(ID3D11DeviceChild)
  ['{e4819ddc-4cf0-4025-bd26-5de82a3e07b7}']
  end;

  { ID3D11GeometryShader }

  ID3D11GeometryShader = interface(ID3D11DeviceChild)
  ['{38325b96-effb-4022-ba02-2e795b70275c}']
  end;

  { ID3D11Asynchronous }

  ID3D11Asynchronous = interface(ID3D11DeviceChild)
  ['{4b35d0cd-1e15-4258-9c98-1b1333f6dd3b}']
    function GetDataSize(): UINT; stdcall;
  end;

  { ID3D11BlendState }

  ID3D11BlendState = interface(ID3D11DeviceChild)
  ['{75b68faa-347d-4159-8f45-a0640f01cd9a}']
  //  procedure GetDesc(out pDesc: TD3D11_BLEND_DESC); stdcall;
  end;

  { ID3D11CommandList }

  ID3D11CommandList = interface(ID3D11DeviceChild)
  ['{a24bc4d1-769e-43f7-8013-98ff566c18e2}']
    function GetContextFlags: UINT; stdcall;
  end;

  { ID3D11HullShader }

  ID3D11HullShader = interface(ID3D11DeviceChild)
  ['{8e5c6061-628a-4c8e-8264-bbe45cb3d5dd}']
  end;

  { ID3D11DomainShader }

  ID3D11DomainShader = interface(ID3D11DeviceChild)
  ['{f582c508-0f36-490c-9977-31eece268cfa}']
  end;

  { ID3D11ComputeShader }

  ID3D11ComputeShader = interface(ID3D11DeviceChild)
  ['{4f5b196e-c2bd-495e-bd01-1fded38e4969}']
  end;

  { ID3D11Device }


  ID3D11Device = interface(IUnknown)
  [SID_ID3D11Device]
    function CreateBuffer(const pDesc: TD3D11BufferDesc; pInitialData: PD3D11SubResourceData; out ppBuffer: ID3D11Buffer): HResult; stdcall;
    function CreateTexture1D(pDesc: Pointer{PD3D11_TEXTURE1D_DESC}; pInitialData: PD3D11SubResourceData; out ppTexture1D: IUnknown{ID3D11Texture1D}): HResult; stdcall;
    function CreateTexture2D(const pDesc: TD3D11Texture2DDesc; pInitialData: PD3D11SubResourceData; out ppTexture2D: ID3D11Texture2D): HResult; stdcall;
  end;

  { ID3D11DeviceContext }

  ID3D11DeviceContext = interface(ID3D11DeviceChild)
  [SID_ID3D11DeviceContext]
    procedure VSSetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure PSSetShaderResources(StartSlot: UINT; NumViews: UINT; ppShaderResourceViews: PID3D11ShaderResourceView); stdcall;
    procedure PSSetShader(pPixelShader: ID3D11PixelShader; ppClassInstances: PID3D11ClassInstance; NumClassInstances: UINT); stdcall;
    procedure PSSetSamplers(StartSlot: UINT; NumSamplers: UINT; ppSamplers: PID3D11SamplerState); stdcall;
    procedure VSSetShader(pVertexShader: ID3D11VertexShader; ppClassInstances: PID3D11ClassInstance; NumClassInstances: UINT); stdcall;
    procedure DrawIndexed(IndexCount: UINT; StartIndexLocation: UINT; BaseVertexLocation: integer); stdcall;
    procedure Draw(VertexCount: UINT; StartVertexLocation: UINT); stdcall;
    function Map(pResource: ID3D11Resource; Subresource: UINT; MapType: TD3D11_MAP; MapFlags: UINT; out pMappedResource: TD3D11MappedSubResource): HResult; stdcall;
    procedure Unmap(pResource: ID3D11Resource; Subresource: UINT); stdcall;
    procedure PSSetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure IASetInputLayout(pInputLayout: ID3D11InputLayout); stdcall;
    procedure IASetVertexBuffers(StartSlot: UINT; NumBuffers: UINT; ppVertexBuffers: PID3D11Buffer; pStrides: PUINT; pOffsets: PUINT); stdcall;
    procedure IASetIndexBuffer(pIndexBuffer: ID3D11Buffer; Format: DXGI_FORMAT; Offset: UINT); stdcall;
    procedure DrawIndexedInstanced(IndexCountPerInstance: UINT; InstanceCount: UINT; StartIndexLocation: UINT; BaseVertexLocation: integer; StartInstanceLocation: UINT); stdcall;
    procedure DrawInstanced(VertexCountPerInstance: UINT; InstanceCount: UINT; StartVertexLocation: UINT; StartInstanceLocation: UINT); stdcall;
    procedure GSSetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure GSSetShader(pShader: ID3D11GeometryShader; ppClassInstances: PID3D11ClassInstance; NumClassInstances: UINT); stdcall;
    procedure IASetPrimitiveTopology(Topology: TD3D_PRIMITIVE_TOPOLOGY); stdcall;
    procedure VSSetShaderResources(StartSlot: UINT; NumViews: UINT; ppShaderResourceViews: PID3D11ShaderResourceView); stdcall;
    procedure VSSetSamplers(StartSlot: UINT; NumSamplers: UINT; ppSamplers: PID3D11SamplerState); stdcall;
    procedure _Begin(pAsync: ID3D11Asynchronous); stdcall;
    procedure _End(pAsync: ID3D11Asynchronous); stdcall;
    function GetData(pAsync: ID3D11Asynchronous; out pData: Pointer; DataSize: UINT; GetDataFlags: UINT): HResult; stdcall;
    procedure SetPredication(pPredicate: IUnknown{ID3D11Predicate}; PredicateValue: LongBool); stdcall;
    procedure GSSetShaderResources(StartSlot: UINT; NumViews: UINT; ppShaderResourceViews: PID3D11ShaderResourceView); stdcall;
    procedure GSSetSamplers(StartSlot: UINT; NumSamplers: UINT; ppSamplers: PID3D11SamplerState); stdcall;
    procedure OMSetRenderTargets(NumViews: UINT; ppRenderTargetViews: PID3D11RenderTargetView; pDepthStencilView: ID3D11DepthStencilView); stdcall;
    procedure OMSetRenderTargetsAndUnorderedAccessViews(NumRTVs: UINT; ppRenderTargetViews: PID3D11RenderTargetView;
      pDepthStencilView: ID3D11DepthStencilView; UAVStartSlot: UINT; NumUAVs: UINT;
      ppUnorderedAccessViews: PID3D11UnorderedAccessView; pUAVInitialCounts: PUINT); stdcall;
    procedure OMSetBlendState(pBlendState: ID3D11BlendState; BlendFactor: TFloatArray4; SampleMask: UINT); stdcall;
    procedure OMSetDepthStencilState(pDepthStencilState: IUnknown{ID3D11DepthStencilState}; StencilRef: UINT); stdcall;
    procedure SOSetTargets(NumBuffers: UINT; ppSOTargets: PID3D11Buffer; pOffsets: PUINT); stdcall;
    procedure DrawAuto; stdcall;
    procedure DrawIndexedInstancedIndirect(pBufferForArgs: ID3D11Buffer; AlignedByteOffsetForArgs: UINT); stdcall;
    procedure DrawInstancedIndirect(pBufferForArgs: ID3D11Buffer; AlignedByteOffsetForArgs: UINT); stdcall;
    procedure Dispatch(ThreadGroupCountX: UINT; ThreadGroupCountY: UINT; ThreadGroupCountZ: UINT); stdcall;
    procedure DispatchIndirect(pBufferForArgs: ID3D11Buffer; AlignedByteOffsetForArgs: UINT); stdcall;
    procedure RSSetState(pRasterizerState: IUnknown{ID3D11RasterizerState}); stdcall;
    procedure RSSetViewports(NumViewports: UINT; pViewports: PD3D11ViewPort); stdcall;
    procedure RSSetScissorRects(NumRects: UINT; pRects: PD3D11Rect); stdcall;
    procedure CopySubresourceRegion(pDstResource: ID3D11Resource; DstSubresource: UInt;
      DstX, DstY, DstZ: UINT; pSrcResource: ID3D11Resource; SrcSubresource: UINT; pSrcBox: PD3D11Box); stdcall;
    procedure CopyResource(pDstResource: ID3D11Resource; pSrcResource: ID3D11Resource); stdcall;
    procedure UpdateSubresource(pDstResource: ID3D11Resource; DstSubresource: UINT; pDstBox: PD3D11Box;
        pSrcData: Pointer; SrcRowPitch: UINT; SrcDepthPitch: UINT); stdcall;
    procedure CopyStructureCount(pDstBuffer: ID3D11Buffer; DstAlignedByteOffset: UINT; pSrcView: ID3D11UnorderedAccessView); stdcall;
    procedure ClearRenderTargetView(pRenderTargetView: IUnknown{ID3D11RenderTargetView}; ColorRGBA: TFloatArray4); stdcall;
    procedure ClearUnorderedAccessViewUINT(pUnorderedAccessView: ID3D11UnorderedAccessView; Values: TUINTArray4); stdcall;
    procedure ClearUnorderedAccessViewFloat(pUnorderedAccessView: ID3D11UnorderedAccessView; Values: TFloatArray4); stdcall;
    procedure ClearDepthStencilView(pDepthStencilView: ID3D11DepthStencilView; ClearFlags: UINT; Depth: single; Stencil: UINT8); stdcall;
    procedure GenerateMips(pShaderResourceView: ID3D11ShaderResourceView); stdcall;
    procedure SetResourceMinLOD(pResource: ID3D11Resource; MinLOD: single); stdcall;
    function GetResourceMinLOD(pResource: ID3D11Resource): single; stdcall;
    procedure ResolveSubresource(pDstResource: ID3D11Resource; DstSubresource: UINT; pSrcResource: ID3D11Resource; SrcSubresource: UINT; Format: DXGI_FORMAT); stdcall;
    procedure ExecuteCommandList(pCommandList: ID3D11CommandList; RestoreContextState: LongBool); stdcall;
    procedure HSSetShaderResources(StartSlot: UINT; NumViews: UINT; ppShaderResourceViews: PID3D11ShaderResourceView); stdcall;
    procedure HSSetShader(pHullShader: ID3D11HullShader; ppClassInstances: PID3D11ClassInstance; NumClassInstances: UINT); stdcall;
    procedure HSSetSamplers(StartSlot: UINT; NumSamplers: UINT; ppSamplers: PID3D11SamplerState); stdcall;
    procedure HSSetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure DSSetShaderResources(StartSlot: UINT; NumViews: UINT; ppShaderResourceViews: PID3D11ShaderResourceView); stdcall;
    procedure DSSetShader(pDomainShader: ID3D11DomainShader; ppClassInstances: PID3D11ClassInstance; NumClassInstances: UINT); stdcall;
    procedure DSSetSamplers(StartSlot: UINT; NumSamplers: UINT; ppSamplers: ID3D11SamplerState); stdcall;
    procedure DSSetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure CSSetShaderResources(StartSlot: UINT; NumViews: UINT; ppShaderResourceViews: ID3D11ShaderResourceView); stdcall;
    procedure CSSetUnorderedAccessViews(StartSlot: UINT; NumUAVs: UINT; ppUnorderedAccessViews: PID3D11UnorderedAccessView; pUAVInitialCounts: PUINT); stdcall;
    procedure CSSetShader(pComputeShader: ID3D11ComputeShader; ppClassInstances: PID3D11ClassInstance; NumClassInstances: UINT); stdcall;
    procedure CSSetSamplers(StartSlot: UINT; NumSamplers: UINT; ppSamplers: PID3D11SamplerState); stdcall;
    procedure CSSetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure VSGetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; out ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure PSGetShaderResources(StartSlot: UINT; NumViews: UINT; out ppShaderResourceViews: PID3D11ShaderResourceView); stdcall;
    procedure PSGetShader(out ppPixelShader: ID3D11PixelShader; out ppClassInstances: PID3D11ClassInstance; var pNumClassInstances: UINT); stdcall;
    procedure PSGetSamplers(StartSlot: UINT; NumSamplers: UINT; out ppSamplers: PID3D11SamplerState); stdcall;
    procedure VSGetShader(out ppVertexShader: ID3D11VertexShader; out ppClassInstances: PID3D11ClassInstance; var pNumClassInstances: UINT); stdcall;
    procedure PSGetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; out ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure IAGetInputLayout(out ppInputLayout: ID3D11InputLayout); stdcall;
    procedure IAGetVertexBuffers(StartSlot: UINT; NumBuffers: UINT; out ppVertexBuffers: PID3D11Buffer; out pStrides: PUINT; out pOffsets: PUINT); stdcall;
    procedure IAGetIndexBuffer(out pIndexBuffer: ID3D11Buffer; out Format: DXGI_FORMAT; out Offset: UINT); stdcall;
    procedure GSGetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; out ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure GSGetShader(out ppGeometryShader: ID3D11GeometryShader; out ppClassInstances: PID3D11ClassInstance; var pNumClassInstances: UINT); stdcall;
    procedure IAGetPrimitiveTopology(out pTopology: TD3D_PRIMITIVE_TOPOLOGY); stdcall;
    procedure VSGetShaderResources(StartSlot: UINT; NumViews: UINT; out ppShaderResourceViews: PID3D11ShaderResourceView); stdcall;
    procedure VSGetSamplers(StartSlot: UINT; NumSamplers: UINT; out ppSamplers: PID3D11SamplerState); stdcall;
    procedure GetPredication(out ppPredicate: IUnknown{ID3D11Predicate}; out pPredicateValue: LongBool); stdcall;
    procedure GSGetShaderResources(StartSlot: UINT; NumViews: UINT; out ppShaderResourceViews: PID3D11ShaderResourceView); stdcall;
    procedure GSGetSamplers(StartSlot: UINT; NumSamplers: UINT; out ppSamplers: PID3D11SamplerState); stdcall;
    procedure OMGetRenderTargets(NumViews: UINT; out ppRenderTargetViews: PID3D11RenderTargetView; out ppDepthStencilView: ID3D11DepthStencilView); stdcall;
    procedure OMGetRenderTargetsAndUnorderedAccessViews(NumRTVs: UINT; out ppRenderTargetViews: PID3D11RenderTargetView;
      out ppDepthStencilView: ID3D11DepthStencilView; UAVStartSlot: UINT; NumUAVs: UINT; out ppUnorderedAccessViews: PID3D11UnorderedAccessView); stdcall;
    procedure OMGetBlendState(out ppBlendState: ID3D11BlendState; out BlendFactor: TFloatArray4; out pSampleMask: UINT); stdcall;
    procedure OMGetDepthStencilState(out ppDepthStencilState: IUnknown{ID3D11DepthStencilState}; out pStencilRef: UINT); stdcall;
    procedure SOGetTargets(NumBuffers: UINT; out ppSOTargets: PID3D11Buffer); stdcall;
    procedure RSGetState(out ppRasterizerState: IUnknown{ID3D11RasterizerState}); stdcall;
    procedure RSGetViewports(var pNumViewports: UINT; out pViewports: PD3D11ViewPort); stdcall;
    procedure RSGetScissorRects(var pNumRects: UINT; out pRects: PD3D11Rect); stdcall;
    procedure HSGetShaderResources(StartSlot: UINT; NumViews: UINT; out ppShaderResourceViews: PID3D11ShaderResourceView); stdcall;
    procedure HSGetShader(out ppHullShader: ID3D11HullShader; out ppClassInstances: PID3D11ClassInstance; var pNumClassInstances: UINT); stdcall;
    procedure HSGetSamplers(StartSlot: UINT; NumSamplers: UINT; out ppSamplers: PID3D11SamplerState); stdcall;
    procedure HSGetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; out ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure DSGetShaderResources(StartSlot: UINT; NumViews: UINT; out ppShaderResourceViews: PID3D11ShaderResourceView); stdcall;
    procedure DSGetShader(out ppDomainShader: ID3D11DomainShader; out ppClassInstances: PID3D11ClassInstance; var pNumClassInstances: UINT); stdcall;
    procedure DSGetSamplers(StartSlot: UINT; NumSamplers: UINT; out ppSamplers: PID3D11SamplerState); stdcall;
    procedure DSGetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; out ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure CSGetShaderResources(StartSlot: UINT; NumViews: UINT; out ppShaderResourceViews: PID3D11ShaderResourceView); stdcall;
    procedure CSGetUnorderedAccessViews(StartSlot: UINT; NumUAVs: UINT; out ppUnorderedAccessViews: PID3D11UnorderedAccessView); stdcall;
    procedure CSGetShader(out ppComputeShader: ID3D11ComputeShader; out ppClassInstances: PID3D11ClassInstance; var pNumClassInstances: UINT); stdcall;
    procedure CSGetSamplers(StartSlot: UINT; NumSamplers: UINT; out ppSamplers: PID3D11SamplerState); stdcall;
    procedure CSGetConstantBuffers(StartSlot: UINT; NumBuffers: UINT; out ppConstantBuffers: PID3D11Buffer); stdcall;
    procedure ClearState; stdcall;
    procedure Flush; stdcall;
    function GetType: TD3D11_DEVICE_CONTEXT_TYPE; stdcall;
    function GetContextFlags: UINT; stdcall;
    function FinishCommandList(RestoreDeferredContextState: LongBool; out ppCommandList: ID3D11CommandList): HResult; stdcall;
  end;

// ---------------------------------------------------------------------------------------------------------------------
// Direct Composition
// ---------------------------------------------------------------------------------------------------------------------

const
  DCompLib = 'Dcomp.dll';

type
  TDCompositionBackfaceVisibility = type Integer;
  TDCompositionBitmapInterpolation = type Integer;
  TDCompositionBorderMode = type Integer;
  TDCompositionCompositeMode = type Integer;
  TDCompositionOpacityMode = type Integer;

const
  DCOMPOSITION_BITMAP_INTERPOLATION_MODE_NEAREST_NEIGHBOR = 0;
  DCOMPOSITION_BITMAP_INTERPOLATION_MODE_LINEAR = 1;

  DCOMPOSITION_BORDER_MODE_SOFT = 0;
  DCOMPOSITION_BORDER_MODE_HARD = 1;

  DCOMPOSITION_COMPOSITE_MODE_SOURCE_OVER = 0;
  DCOMPOSITION_COMPOSITE_MODE_DESTINATION_INVERT = 1;
  DCOMPOSITION_COMPOSITE_MODE_MIN_BLEND = 2;

  DCOMPOSITION_OPACITY_MODE_LAYER = 0;
  DCOMPOSITION_OPACITY_MODE_MULTIPLY = 1;

  DCOMPOSITION_BACKFACE_VISIBILITY_VISIBLE = 0;
  DCOMPOSITION_BACKFACE_VISIBILITY_HIDDEN = 1;

type
  PDCompositionFrameStatistics = ^TDCompositionFrameStatistics;
  TDCompositionFrameStatistics = record
    lastFrameTime: TLargeInteger;
    currentCompositionRate: TDXGIRational;
    currentTime: TLargeInteger;
    timeFrequency: TLargeInteger;
    nextEstimatedFrameTime: TLargeInteger;
  end;

  { IDCompositionEffect }

  IDCompositionEffect = interface(IUnknown)
  ['{EC81B08F-BFCB-4e8d-B193-A915587999E8}']
  end;

  { IDCompositionVisual }

  IDCompositionVisual = interface(IUnknown)
  ['{4d93059d-097b-4651-9a60-f0f25116e2f3}']
    function SetOffsetX(animation: IUnknown{IDCompositionAnimation}): HResult; stdcall; overload;
    function SetOffsetX(offsetX: single): HResult; stdcall; overload;
    function SetOffsetY(animation: IUnknown{IDCompositionAnimation}): HResult; stdcall; overload;
    function SetOffsetY(offsetY: single): HResult; stdcall; overload;
    function SetTransform(const matrix: TD2DMatrix3x2F): HResult; stdcall;
    function _SetTransform(transform: IUnknown{IDCompositionTransform}): HResult; stdcall;
    function SetTransformParent(visual: IDCompositionVisual): HResult; stdcall;
    function SetEffect(effect: IDCompositionEffect): HResult; stdcall;
    function SetBitmapInterpolationMode(interpolationMode: TDCompositionBitmapInterpolation): HResult; stdcall;
    function SetBorderMode(borderMode: TDCompositionBorderMode): HResult; stdcall;
    function SetClip(const rect: TD2DRectF): HResult; stdcall;
    function _SetClip(clip: IUnknown{IDCompositionClip}): HResult; stdcall;
    function SetContent(content: IUnknown): HResult; stdcall;
    function AddVisual(visual: IDCompositionVisual; insertAbove: boolean; referenceVisual: IDCompositionVisual): HResult; stdcall;
    function RemoveVisual(visual: IDCompositionVisual): HResult; stdcall;
    function RemoveAllVisuals: HResult; stdcall;
    function SetCompositeMode(compositeMode: TDCompositionCompositeMode): HResult; stdcall;
  end;

  { IDCompositionTarget }

  IDCompositionTarget = interface(IUnknown)
  ['{eacdd04c-117e-4e17-88f4-d1b12b0e3d89}']
    function SetRoot(visual: IDCompositionVisual): HResult; stdcall;
  end;

  { IDCompositionVisual2 }

  IDCompositionVisual2 = interface(IDCompositionVisual)
  ['{E8DE1639-4331-4B26-BC5F-6A321D347A85}']
    function SetOpacityMode(mode: TDCompositionOpacityMode): HResult; stdcall;
    function SetBackFaceVisibility(visibility: TDCompositionBackfaceVisibility): HResult; stdcall;
  end;

  IDCompositionDevice = interface(IUnknown)
  ['{C37EA93A-E7AA-450D-B16F-9746CB0407F3}']
    function Commit: HResult; stdcall;
    function WaitForCommitCompletion: HResult; stdcall;
    function GetFrameStatistics(out statistics: TDCompositionFrameStatistics): HResult; stdcall;
    function CreateTargetForHwnd(hwnd: HWND; topmost: boolean; out target: IDCompositionTarget): HResult; stdcall;
    function CreateVisual(out visual: IDCompositionVisual): HResult; stdcall;
    function CreateSurface(Width: UINT; Height: UINT; pixelFormat: DXGI_FORMAT; alphaMode: TDXGIAlphaMode;
      out surface: IUnknown{IDCompositionSurface}): HResult; stdcall;
    function CreateVirtualSurface(initialWidth: UINT; initialHeight: UINT; pixelFormat: DXGI_FORMAT;
      alphaMode: TDXGIAlphaMode; out virtualSurface: IUnknown{IDCompositionVirtualSurface}): HResult; stdcall;
    function CreateSurfaceFromHandle(handle: THANDLE; out surface: IUnknown): HResult; stdcall;
    function CreateSurfaceFromHwnd(hwnd: HWND; out surface: IUnknown): HResult; stdcall;
    function CreateTranslateTransform(out translateTransform: IUnknown{IDCompositionTranslateTransform}): HResult; stdcall;
    function CreateScaleTransform(out scaleTransform: IUnknown{IDCompositionScaleTransform}): HResult; stdcall;
    function CreateRotateTransform(out rotateTransform: IUnknown{IDCompositionRotateTransform}): HResult; stdcall;
    function CreateSkewTransform(out skewTransform: IUnknown{IDCompositionSkewTransform}): HResult; stdcall;
    function CreateMatrixTransform(out matrixTransform: IUnknown{IDCompositionMatrixTransform}): HResult; stdcall;
    function CreateTransformGroup(transforms: Pointer{PIDCompositionTransform}; elements: UINT;
      out transformGroup: IUnknown{IDCompositionTransform}): HResult; stdcall;
    function CreateTranslateTransform3D(out translateTransform3D: IUnknown{IDCompositionTranslateTransform3D}): HResult; stdcall;
    function CreateScaleTransform3D(out scaleTransform3D: IUnknown{IDCompositionScaleTransform3D}): HResult; stdcall;
    function CreateRotateTransform3D(out rotateTransform3D: IUnknown{IDCompositionRotateTransform3D}): HResult; stdcall;
    function CreateMatrixTransform3D(out matrixTransform3D: IUnknown{IDCompositionMatrixTransform3D}): HResult; stdcall;
    function CreateTransform3DGroup(transforms3D: Pointer{PIDCompositionTransform3D}; elements: UINT;
        out transform3DGroup: IUnknown{IDCompositionTransform3D}): HResult; stdcall;
    function CreateEffectGroup(out effectGroup: IUnknown{IDCompositionEffectGroup}): HResult; stdcall;
    function CreateRectangleClip(out clip: IUnknown{IDCompositionRectangleClip}): HResult; stdcall;
    function CreateAnimation(out animation: IUnknown{IDCompositionAnimation}): HResult; stdcall;
    function CheckDeviceState(out pfValid: boolean): HResult; stdcall;
  end;

  { IDCompositionDevice2 }

  IDCompositionDevice2 = interface(IUnknown)
  ['{75F6468D-1B8E-447C-9BC6-75FEA80B5B25}']
    function Commit: HResult; stdcall;
    function WaitForCommitCompletion: HResult; stdcall;
    function GetFrameStatistics(out statistics: TDCompositionFrameStatistics): HResult; stdcall;
    function CreateVisual(out visual: IDCompositionVisual2): HResult; stdcall;
    function CreateSurfaceFactory(renderingDevice: IUnknown; out surfaceFactory: {IDCompositionSurfaceFactory}IUnknown): HResult; stdcall;
    function CreateSurface(Width: UINT; Height: UINT; pixelFormat: DXGI_FORMAT;
      alphaMode: TDXGIAlphaMode; out surface: {IDCompositionSurface}IUnknown): HResult; stdcall;
    function CreateVirtualSurface(initialWidth: UINT; initialHeight: UINT; pixelFormat: DXGI_FORMAT; alphaMode: TDXGIAlphaMode;
      out virtualSurface: IUnknown{IDCompositionVirtualSurface}): HResult; stdcall;
    function CreateTranslateTransform(out translateTransform: IUnknown{IDCompositionTranslateTransform}): HResult; stdcall;
    function CreateScaleTransform(out scaleTransform: IUnknown{IDCompositionScaleTransform}): HResult; stdcall;
    function CreateRotateTransform(out rotateTransform: IUnknown{IDCompositionRotateTransform}): HResult; stdcall;
    function CreateSkewTransform(out skewTransform: IUnknown{IDCompositionSkewTransform}): HResult; stdcall;
    function CreateMatrixTransform(out matrixTransform: IUnknown{IDCompositionMatrixTransform}): HResult; stdcall;
    function CreateTransformGroup(transforms: Pointer{PIDCompositionTransform}; elements: UINT; out transformGroup: IUnknown{IDCompositionTransform}): HResult; stdcall;
    function CreateTranslateTransform3D(out translateTransform3D: IUnknown{IDCompositionTranslateTransform3D}): HResult; stdcall;
    function CreateScaleTransform3D(out scaleTransform3D: IUnknown{IDCompositionScaleTransform3D}): HResult; stdcall;
    function CreateRotateTransform3D(out rotateTransform3D: IUnknown{IDCompositionRotateTransform3D}): HResult; stdcall;
    function CreateMatrixTransform3D(out matrixTransform3D: IUnknown{IDCompositionMatrixTransform3D}): HResult; stdcall;
    function CreateTransform3DGroup(transforms3D: Pointer{PIDCompositionTransform3D}; elements: UINT;
      out transform3DGroup: IUnknown{IDCompositionTransform3D}): HResult; stdcall;
    function CreateEffectGroup(out effectGroup: IUnknown{IDCompositionEffectGroup}): HResult; stdcall;
    function CreateRectangleClip(out clip: IUnknown{IDCompositionRectangleClip}): HResult; stdcall;
    function CreateAnimation(out animation: IUnknown{IDCompositionAnimation}): HResult; stdcall;
  end;

  { IDCompositionDesktopDevice }

  IDCompositionDesktopDevice = interface(IDCompositionDevice2)
  ['{5F4633FE-1E08-4CB8-8C75-CE24333F5602}']
    function CreateTargetForHwnd(hwnd: HWND; topmost: boolean; out target: IDCompositionTarget): HResult; stdcall;
    function CreateSurfaceFromHandle(handle: THANDLE; out surface: IUnknown): HResult; stdcall;
    function CreateSurfaceFromHwnd(hwnd: HWND; out surface: IUnknown): HResult; stdcall;
  end;

implementation

{ TD3D11Box }

class function TD3D11Box.Create(const ALeft, ATop, ARight, ABottom: LongInt; AFront, ABack: LongInt): TD3D11Box;
begin
  Result.left := ALeft;
  Result.top := ATop;
  Result.front := AFront;
  Result.right := ARight;
  Result.bottom := ABottom;
  Result.back := ABack;
end;

class function TD3D11Box.Create(const ARect: TRect): TD3D11Box;
begin
  Result := Create(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom, 0, 1);
end;

class operator TD3D11Box.Equal(const A, B: TD3D11Box): LongBool;
begin
  Result :=
    (A.left = B.left) and
    (A.top = B.top) and
    (A.front = B.front) and
    (A.right = B.right) and
    (A.bottom = B.bottom) and
    (A.back = B.back);
end;

class operator TD3D11Box.NotEqual(const A, B: TD3D11Box): LongBool;
begin
  Result := not (A = B);
end;

{ TD3D11BufferDesc }

procedure TD3D11BufferDesc.Init(AByteWidth: UINT; ABindFlags: UINT;
  AUsage: TD3D11_USAGE; ACPUAccessFlags: UINT; AMiscFlags: UINT; AStructureByteStride: UINT);
begin
  ByteWidth := AByteWidth;
  Usage := AUsage;
  BindFlags := ABindFlags;
  CPUAccessFlags := ACpuAccessFlags;
  MiscFlags := AMiscFlags;
  StructureByteStride := AStructureByteStride;
end;

end.
