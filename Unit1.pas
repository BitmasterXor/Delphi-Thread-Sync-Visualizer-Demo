{*******************************************************
  Unit: Thread Synchronization Visualization

  Purpose:
    Demonstrates thread synchronization using visual progress bars.
    Shows real-time thread states and synchronization points.

  Features:
    - Three parallel worker threads
    - Visual progress tracking
    - Synchronization at 25%, 50%, and 75% points
    - Color-coded thread states

  Author: BitmasterXor
  Date: December 12/25/2024
********************************************************}

unit Unit1;

interface

uses
  // Standard VCL and Windows components
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, commctrl, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.StdCtrls,
  // Thread synchronization and JEDI visual components
  System.SyncObjs, JvProgressBar, JvXPProgressBar;

type
  {
    TWorkThread
    Purpose: Worker thread that manages progress updates and synchronization
    Features:
      - Progress bar visualization
      - Event-based synchronization
      - Color-coded state indication
  }
  TWorkThread = class(TThread)
  private
    FProgressBar: TJvXPProgressBar;    // Visual progress indicator
    FEvent: TEvent;                    // Synchronization control
    FPosition: Integer;                // Current progress position
    procedure UpdateProgress;          // Thread-safe progress update
  protected
    procedure Execute; override;       // Main thread execution logic
  public
    constructor Create(AProgressBar: TJvXPProgressBar);
    destructor Destroy; override;
    procedure SignalThread;            // Triggers thread continuation
    property SyncEvent: TEvent read FEvent;
  end;

  {
    TForm1
    Purpose: Main form managing thread visualization and control
  }
  TForm1 = class(TForm)
    btnStart: TButton;                // Initiates thread simulation
    btnSync: TButton;                 // Triggers synchronization
    Label1: TLabel;                   // Thread 1 identifier
    Label2: TLabel;                   // Thread 2 identifier
    Label3: TLabel;                   // Thread 3 identifier
    JvXPProgressBar1: TJvXPProgressBar;  // Thread 1 progress
    JvXPProgressBar2: TJvXPProgressBar;  // Thread 2 progress
    JvXPProgressBar3: TJvXPProgressBar;
    Button1: TButton;  // Thread 3 progress
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnSyncClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    FThreads: array[0..2] of TWorkThread;  // Worker threads collection
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ TWorkThread }

{
  Constructor: Initializes thread in suspended state
  @param AProgressBar - Progress bar for visual feedback
}
constructor TWorkThread.Create(AProgressBar: TJvXPProgressBar);
begin
  inherited Create(True);             // Create suspended
  FProgressBar := AProgressBar;       // Assign progress bar
  FEvent := TEvent.Create(nil, True, False, '');  // Create sync event
  FPosition := 0;                     // Initialize position
end;

{
  Destructor: Ensures proper cleanup of thread resources
}
destructor TWorkThread.Destroy;
begin
  FEvent.Free;                        // Clean up event
  inherited;
end;

{
  Execute: Main thread processing loop
  - Updates progress
  - Handles synchronization points
  - Manages visual state indication
}
procedure TWorkThread.Execute;
begin
  while not Terminated do
  begin
    // Progress update section
    if FPosition < 100 then
    begin
      Inc(FPosition);
      Synchronize(UpdateProgress);
      Sleep(Random(100));             // Simulate varying work speeds
    end;

    // Synchronization checkpoint handling
    if (FPosition in [25, 50, 75]) then
    begin
      // Visual indication: Waiting state
      Synchronize(procedure
      begin
        FProgressBar.BarColorFrom := clYellow;
        FProgressBar.BarColorTo := clYellow;
      end);


      FEvent.WaitFor;                 // Wait for sync signal
      FEvent.ResetEvent;              // Reset for next sync point

      // Visual indication: Just synchronized
      Synchronize(procedure
      begin
        FProgressBar.BarColorFrom := clLime;
        FProgressBar.BarColorTo := clLime;
      end);

      Sleep(200);                     // Brief visual feedback

      // Visual indication: Normal operation
      Synchronize(procedure
      begin
        FProgressBar.BarColorFrom := clGreen;
        FProgressBar.BarColorTo := clGreen;
      end);
    end;
  end;
end;

{
  UpdateProgress: Thread-safe progress bar update
}
procedure TWorkThread.UpdateProgress;
begin
FProgressBar.Position := FPosition;
end;

{
  SignalThread: Triggers thread to continue processing
}
procedure TWorkThread.SignalThread;
begin
  FEvent.SetEvent;
end;

{ TForm1 }

{
  FormCreate: Form initialization
  - Initializes thread array
}
procedure TForm1.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to 2 do
  begin
    FThreads[i] := nil;               // Initialize thread array
  end;
end;

{
  FormDestroy: Cleanup
  - Ensures proper thread termination
  - Frees thread resources
}
procedure TForm1.FormDestroy(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to 2 do
  begin
    if Assigned(FThreads[i]) then
    begin
      FThreads[i].Terminate;          // Signal thread to stop
      FThreads[i].SignalThread;       // Wake if waiting
      FThreads[i].WaitFor;            // Wait for completion
      FThreads[i].Free;               // Free thread
    end;
  end;
end;

{
  btnStartClick: Initiates thread simulation
  - Resets progress bars
  - Creates and starts worker threads
}
procedure TForm1.btnStartClick(Sender: TObject);
var
  i: Integer;
begin
//make sure all progressbars are GREEN FIRST!!!
self.JvXPProgressBar1.BarColorFrom:=CLgreen;
  self.JvXPProgressBar1.BarColorTo:=CLgreen;
  self.JvXPProgressBar2.BarColorFrom:=CLgreen;
  self.JvXPProgressBar2.BarColorTo:=CLgreen;
  self.JvXPProgressBar3.BarColorFrom:=CLgreen;
  self.JvXPProgressBar3.BarColorTo:=CLgreen;

  // Reset progress indicators
  JvXPProgressBar1.Position := 0;
  JvXPProgressBar2.Position := 0;
  JvXPProgressBar3.Position := 0;

  // Initialize and start threads
  for i := 0 to 2 do // in other words we are counting to 3
  begin
    case i of //creating 3 Threads and assigning each thread its own progressbar on our main form...
      0: FThreads[i] := TWorkThread.Create(JvXPProgressBar1);
      1: FThreads[i] := TWorkThread.Create(JvXPProgressBar2);
      2: FThreads[i] := TWorkThread.Create(JvXPProgressBar3);
    end;
    FThreads[i].Start; //Starting all threads at the exact same time!
  end;

  // Update buttons to represent what we need them to...
  // in this case we already started running threads so lets disable the start button and enable the SYNC button!
  btnStart.Enabled := False;
  btnSync.Enabled := True;
  button1.Enabled:=true;
end;

{
  btnSyncClick: Triggers thread synchronization
  - Signals all threads to continue processing
}
procedure TForm1.btnSyncClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to 2 do
  begin
    if Assigned(FThreads[i]) then
      FThreads[i].SignalThread;       // Signal threads to continue
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  i: Integer;
begin
  // Loop through all threads
  for i := 0 to 2 do
  begin
    if Assigned(FThreads[i]) then
    begin
      FThreads[i].Terminate;          // Tell thread to stop
      FThreads[i].SignalThread;       // Wake it up if it's waiting
      FThreads[i].WaitFor;            // Wait for it to finish
      FThreads[i].Free;               // Free the thread
      FThreads[i] := nil;             // Clear the reference
    end;
  end;

  // Reset UI state
  btnStart.Enabled := True;           // Allow starting new threads
  btnSync.Enabled := False;           // Can't sync stopped threads
  button1.Enabled:=false;


  //OPTIONAL You could reset the progressbars back to 0 here if you would like too... Ill make them RED so you know they are stopped....
  self.JvXPProgressBar1.BarColorFrom:=CLRed;
  self.JvXPProgressBar1.BarColorTo:=CLRed;
  self.JvXPProgressBar2.BarColorFrom:=CLRed;
  self.JvXPProgressBar2.BarColorTo:=CLRed;
  self.JvXPProgressBar3.BarColorFrom:=CLRed;
  self.JvXPProgressBar3.BarColorTo:=CLRed;
end;

end.
