program LogicaPDV;

uses
  Vcl.Forms,
  Main in 'src\Main.pas',
  Store in 'src\Store.pas';


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
