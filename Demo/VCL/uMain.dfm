object fMain: TfMain
  Left = 0
  Top = 0
  Caption = 'Video Player'
  ClientHeight = 378
  ClientWidth = 628
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object pButtons: TPanel
    Left = 0
    Top = 341
    Width = 628
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'pButtons'
    ShowCaption = False
    TabOrder = 0
    DesignSize = (
      628
      37)
    object lTime: TLabel
      Left = 544
      Top = 0
      Width = 45
      Height = 37
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
    end
    object bOpen: TButton
      Left = 8
      Top = 6
      Width = 65
      Height = 25
      Action = FileOpen
      TabOrder = 0
    end
    object bPlay: TButton
      Left = 79
      Top = 6
      Width = 25
      Height = 25
      Action = aPlay
      Caption = #9654
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI Emoji'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object bPause: TButton
      Left = 110
      Top = 6
      Width = 25
      Height = 25
      Action = aPause
      Caption = #9208
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI Emoji'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object bStop: TButton
      Left = 141
      Top = 6
      Width = 25
      Height = 25
      Action = aStop
      Caption = #9209
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI Emoji'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
    object bMute: TButton
      Left = 595
      Top = 6
      Width = 25
      Height = 25
      Action = aMute
      Anchors = [akTop, akRight]
      Caption = #55357#56583
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI Emoji'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
    object tbPosition: TTrackBar
      Left = 172
      Top = 6
      Width = 366
      Height = 45
      Anchors = [akLeft, akTop, akRight]
      Enabled = False
      Max = 100
      PageSize = 10
      PositionToolTip = ptTop
      TabOrder = 5
      TickMarks = tmBoth
      TickStyle = tsNone
      OnTracking = tbPositionTracking
    end
  end
  object XAMLMediaPlayer: TXAMLMediaPlayer
    Left = 0
    Top = 0
    Width = 628
    Height = 341
    Align = alClient
    OnClick = XAMLMediaPlayerClick
    OnContextPopup = XAMLMediaPlayerContextPopup
    OnStateChange = XAMLMediaPlayerStateChange
  end
  object tTimeUpdate: TTimer
    Enabled = False
    Interval = 100
    OnTimer = tTimeUpdateTimer
    Left = 144
    Top = 40
  end
  object tAction: TTimer
    Interval = 200
    OnTimer = CheckParams
    Left = 216
    Top = 40
  end
  object ActionManager: TActionManager
    Left = 48
    Top = 40
    StyleName = 'Platform Default'
    object FileOpen: TFileOpen
      Category = 'File'
      Caption = '&Open...'
      Hint = 'Open|Opens an existing file'
      ImageIndex = 7
      ShortCut = 16463
      OnAccept = FileOpenClick
    end
    object FileExit: TFileExit
      Category = 'File'
      Caption = 'E&xit'
      Hint = 'Exit|Quits the application'
      ImageIndex = 43
    end
    object aPlay: TAction
      Category = 'Playback'
      Caption = #9654' Play'
      OnExecute = aPlayClick
    end
    object aPause: TAction
      Category = 'Playback'
      Caption = #9208' Pause'
      Enabled = False
      OnExecute = aPauseClick
    end
    object aStop: TAction
      Category = 'Playback'
      Caption = #9209' Stop'
      Enabled = False
      OnExecute = aStopClick
    end
    object aMute: TAction
      Category = 'Audio'
      Caption = #55357#56583' Mute'
      Enabled = False
      OnExecute = aMuteClick
    end
  end
  object PopupActionBar: TPopupActionBar
    Left = 296
    Top = 40
    object Open1: TMenuItem
      Action = FileOpen
    end
    object Play1: TMenuItem
      Action = aPlay
    end
    object Pause1: TMenuItem
      Action = aPause
    end
    object Stop1: TMenuItem
      Action = aStop
    end
    object Mute1: TMenuItem
      Action = aMute
    end
    object Exit1: TMenuItem
      Action = FileExit
    end
  end
end
