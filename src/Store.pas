unit Store;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.IniFiles, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async,
  FireDAC.Stan.Param, FireDAC.DApt, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.Stan.Intf, FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI, FireDAC.VCLUI.Login;

type
  TStore = class
  private
    FConnection: TFDConnection;
  public
    constructor Create;
    destructor Destroy; override;
    function Query(const SQL: string): TFDQuery;
    property Connection: TFDConnection read FConnection;
  end;

implementation

constructor TStore.Create;
var
  Config: TIniFile;
  ConfigPath, ClientPath: string;
  Driver: TFDPhysFBDriverLink;
begin
  inherited;
  FConnection := TFDConnection.Create(nil);
  try
    ConfigPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'LogicaPDV.ini');
    if not FileExists(ConfigPath) then
      raise Exception.Create('Copie LogicaPDV.ini.example para LogicaPDV.ini ' +
        'ao lado do executavel e configure o banco Firebird.');
    Config := TIniFile.Create(ConfigPath);
    try
      Driver := TFDPhysFBDriverLink.Create(FConnection);
      ClientPath := Config.ReadString('Firebird', 'ClientLibrary', 'fbclient.dll');
      if not TPath.IsPathRooted(ClientPath) then
        ClientPath := TPath.Combine(ExtractFilePath(ParamStr(0)), ClientPath);
      if not FileExists(ClientPath) then
        raise Exception.Create('Cliente Firebird nao encontrado: ' + ClientPath);
      Driver.VendorLib := ClientPath;
      FConnection.Params.Values['DriverID'] := 'FB';
      FConnection.Params.Values['Protocol'] := 'TCPIP';
      FConnection.Params.Values['Server'] := Config.ReadString('Firebird', 'Server', 'localhost');
      FConnection.Params.Values['Port'] := Config.ReadString('Firebird', 'Port', '3050');
      FConnection.Params.Values['Database'] := Config.ReadString('Firebird', 'Database', '');
      FConnection.Params.Values['CharacterSet'] := 'UTF8';
      FConnection.Params.Values['SQLDialect'] := '3';
      FConnection.Params.Values['User_Name'] := Config.ReadString('Firebird', 'UserName', 'SYSDBA');
      if FConnection.Params.Values['Database'] = '' then
        raise Exception.Create('Configure Database em LogicaPDV.ini.');
    finally
      Config.Free;
    end;
    // A senha e solicitada pelo FireDAC, sem gravacao no arquivo INI.
    FConnection.LoginPrompt := True;
    FConnection.Connected := True;
    // Falha cedo se o script de criacao ainda nao foi executado.
    with Query('SELECT FIRST 1 id FROM products') do
      Free;
  except
    FreeAndNil(FConnection);
    raise;
  end;
end;

destructor TStore.Destroy;
begin
  FConnection.Free;
  inherited;
end;

function TStore.Query(const SQL: string): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  try
    Result.Connection := FConnection;
    Result.Open(SQL);
  except
    Result.Free;
    raise;
  end;
end;

end.
