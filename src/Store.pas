unit Store;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async,
  FireDAC.Stan.Param, FireDAC.DApt, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.Intf, FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI, FireDAC.Phys.SQLiteWrapper.Stat;

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
  Folder: string;
begin
  inherited;
  FConnection := TFDConnection.Create(nil);
  try
    Folder := TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'LogicaPDV');
    ForceDirectories(Folder);
    FConnection.LoginPrompt := False;
    FConnection.Params.Values['DriverID'] := 'SQLite';
    FConnection.Params.Values['Database'] := TPath.Combine(Folder, 'pdv.sqlite');
    FConnection.Connected := True;
    FConnection.ExecSQL('PRAGMA foreign_keys = ON');
    FConnection.ExecSQL('PRAGMA busy_timeout = 5000');
    FConnection.ExecSQL('CREATE TABLE IF NOT EXISTS products (' +
      'id INTEGER PRIMARY KEY, code TEXT NOT NULL UNIQUE, name TEXT NOT NULL,' +
      'price_cents INTEGER NOT NULL CHECK(price_cents >= 0),' +
      'stock INTEGER NOT NULL DEFAULT 0 CHECK(stock >= 0))');
    FConnection.ExecSQL('CREATE TABLE IF NOT EXISTS customers (' +
      'id INTEGER PRIMARY KEY, name TEXT NOT NULL, document TEXT, phone TEXT)');
    FConnection.ExecSQL('CREATE TABLE IF NOT EXISTS sales (' +
      'id INTEGER PRIMARY KEY, created_at TEXT NOT NULL DEFAULT (datetime(''now'',''localtime'')),' +
      'customer_id INTEGER REFERENCES customers(id), total_cents INTEGER NOT NULL)');
    FConnection.ExecSQL('CREATE TABLE IF NOT EXISTS sale_items (' +
      'id INTEGER PRIMARY KEY, sale_id INTEGER NOT NULL REFERENCES sales(id),' +
      'product_id INTEGER NOT NULL REFERENCES products(id), name TEXT NOT NULL,' +
      'quantity INTEGER NOT NULL CHECK(quantity > 0), unit_cents INTEGER NOT NULL)');
  except
    FConnection.Free;
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
