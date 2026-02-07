# XAMLPlayer
XAMLPlayer is a Delphi component that uses XAML Islands to play media files on Win10 (19H1 and newer) and Win11. It can be compiled in Delphi versions that have WinUIRTL package. So far Delphi 12 and 13 have been tested and work fine.

Manifest of the project that uses XAMLPlayer, should be replaced with a custom one that has "maxversiontested" element. Example manifest is provided. RAD Studio IDE has manifest without this element, that is why this component will not work in design-time.

XAMLPlayer should be able to use any codecs, that have been installed from Microsoft Store.