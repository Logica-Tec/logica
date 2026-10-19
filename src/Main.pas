unit Main;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Grids, Vcl.Dialogs,
  Vcl.Printers, FireDAC.Comp.Client, FireDAC.Stan.Param, Data.DB, Store;

type
  TCartItem = record
    ProductID: Integer;
    Name: string;
    Quantity: Integer;
    UnitCents: Int64;
  end;

  TMainForm = class(TForm)
  private
    DB: TStore;
    Cart: TList<TCartItem>;
    Products, Customers: TListBox;
    CodeEdit, NameEdit, PriceEdit, StockEdit: TEdit;
    CustomerName, DocumentEdit, PhoneEdit, SaleCode, QuantityEdit: TEdit;
    CustomerCombo: TComboBox;
    Grid: TStringGrid;
    TotalLabel: TLabel;
    Receipt: TMemo;
    function NewEdit(ParentControl: TWinControl; const Caption: string;
      X, Y, Width: Integer): TEdit;
    procedure NewButton(ParentControl: TWinControl; const Caption: string;
      X, Y: Integer; Handler: TNotifyEvent);
    procedure RefreshData;
    procedure RenderCart;
    procedure SaveProduct(Sender: TObject);
    procedure SaveCustomer(Sender: TObject);
    procedure AddItem(Sender: TObject);
    procedure RemoveItem(Sender: TObject);
    procedure FinishSale(Sender: TObject);
    procedure PrintReceipt(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

function TMainForm.NewEdit(ParentControl: TWinControl; const Caption: string;
  X, Y, Width: Integer): TEdit;
var L: TLabel;
begin
  L := TLabel.Create(Self);
  L.Parent := ParentControl;
  L.SetBounds(X, Y, Width, 20);
  L.Caption := Caption;
  Result := TEdit.Create(Self);
  Result.Parent := ParentControl;
  Result.SetBounds(X, Y + 22, Width, 25);
end;

procedure TMainForm.NewButton(ParentControl: TWinControl; const Caption: string;
  X, Y: Integer; Handler: TNotifyEvent);
var B: TButton;
begin
  B := TButton.Create(Self);
  B.Parent := ParentControl;
  B.SetBounds(X, Y, 180, 32);
  B.Caption := Caption;
  B.OnClick := Handler;
end;

constructor TMainForm.Create(AOwner: TComponent);
var
  Pages: TPageControl;
  SalesTab, ProductTab, CustomerTab, ReceiptTab: TTabSheet;
  function Tab(const Title: string): TTabSheet;
  begin
    Result := TTabSheet.Create(Self);
    Result.PageControl := Pages;
    Result.Caption := Title;
  end;
begin
  inherited CreateNew(AOwner);
  Caption := 'Logica PDV - prototipo';
  SetBounds(100, 100, 1024, 720);
  Position := poScreenCenter;
  Constraints.MinWidth := 1000;
  Constraints.MinHeight := 680;
  DB := TStore.Create;
  Cart := TList<TCartItem>.Create;
  Pages := TPageControl.Create(Self);
  Pages.Parent := Self;
  Pages.Align := alClient;
  SalesTab := Tab('Vendas');
  ProductTab := Tab('Produtos / estoque');
  CustomerTab := Tab('Clientes');
  ReceiptTab := Tab('Ultimo comprovante');
  CodeEdit := NewEdit(ProductTab, 'Codigo de barras / codigo', 20, 20, 220);
  NameEdit := NewEdit(ProductTab, 'Nome', 260, 20, 380);
  PriceEdit := NewEdit(ProductTab, 'Preco (R$)', 20, 90, 180);
  StockEdit := NewEdit(ProductTab, 'Estoque inicial (unidades)', 220, 90, 220);
  NewButton(ProductTab, 'Cadastrar produto', 20, 160, SaveProduct);
  Products := TListBox.Create(Self);
  Products.Parent := ProductTab;
  Products.SetBounds(20, 210, 900, 340);
  CustomerName := NewEdit(CustomerTab, 'Nome', 20, 20, 400);
  DocumentEdit := NewEdit(CustomerTab, 'CPF / CNPJ (opcional)', 20, 90, 250);
  PhoneEdit := NewEdit(CustomerTab, 'Telefone (opcional)', 290, 90, 250);
  NewButton(CustomerTab, 'Cadastrar cliente', 20, 160, SaveCustomer);
  Customers := TListBox.Create(Self);
  Customers.Parent := CustomerTab;
  Customers.SetBounds(20, 210, 900, 340);
  SaleCode := NewEdit(SalesTab, 'Codigo do produto', 20, 20, 260);
  QuantityEdit := NewEdit(SalesTab, 'Quantidade inteira', 300, 20, 160);
  QuantityEdit.Text := '1';
  NewButton(SalesTab, 'Adicionar item', 480, 40, AddItem);
  CustomerCombo := TComboBox.Create(Self);
  CustomerCombo.Parent := SalesTab;
  CustomerCombo.Style := csDropDownList;
  CustomerCombo.SetBounds(20, 90, 440, 25);
  Grid := TStringGrid.Create(Self);
  Grid.Parent := SalesTab;
  Grid.SetBounds(20, 140, 900, 300);
  Grid.ColCount := 4;
  Grid.RowCount := 2;
  Grid.FixedCols := 0;
  Grid.Cells[0, 0] := 'Produto';
  Grid.Cells[1, 0] := 'Quantidade';
  Grid.Cells[2, 0] := 'Unitario';
  Grid.Cells[3, 0] := 'Subtotal';
  Grid.ColWidths[0] := 480;
  Grid.ColWidths[1] := 100;
  Grid.ColWidths[2] := 130;
  Grid.ColWidths[3] := 150;
  TotalLabel := TLabel.Create(Self);
  TotalLabel.Parent := SalesTab;
  TotalLabel.SetBounds(20, 460, 700, 30);
  TotalLabel.Font.Size := 16;
  NewButton(SalesTab, 'Remover linha', 20, 510, RemoveItem);
  NewButton(SalesTab, 'Finalizar venda', 220, 510, FinishSale);
  Receipt := TMemo.Create(Self);
  Receipt.Parent := ReceiptTab;
  Receipt.SetBounds(20, 20, 900, 470);
  Receipt.ReadOnly := True;
  Receipt.ScrollBars := ssVertical;
  NewButton(ReceiptTab, 'Imprimir comprovante', 20, 510, PrintReceipt);
  RefreshData;
  RenderCart;
end;

destructor TMainForm.Destroy;
begin
  Cart.Free;
  DB.Free;
  inherited;
end;

procedure TMainForm.RefreshData;
var Q: TFDQuery;
begin
  Products.Clear;
  Q := DB.Query('SELECT * FROM products ORDER BY name');
  try
    while not Q.Eof do
    begin
      Products.Items.Add(Format('%s | %s | R$ %.2f | estoque: %d',
        [Q.FieldByName('code').AsString, Q.FieldByName('name').AsString,
         Q.FieldByName('price_cents').AsLargeInt / 100,
         Q.FieldByName('stock').AsInteger]));
      Q.Next;
    end;
  finally Q.Free; end;
  Customers.Clear;
  CustomerCombo.Clear;
  CustomerCombo.Items.AddObject('Consumidor nao identificado', nil);
  Q := DB.Query('SELECT * FROM customers ORDER BY name');
  try
    while not Q.Eof do
    begin
      Customers.Items.Add(Q.FieldByName('name').AsString + ' | ' +
        Q.FieldByName('document').AsString + ' | ' + Q.FieldByName('phone').AsString);
      CustomerCombo.Items.AddObject(Q.FieldByName('name').AsString,
        TObject(NativeInt(Q.FieldByName('id').AsInteger)));
      Q.Next;
    end;
  finally Q.Free; end;
  CustomerCombo.ItemIndex := 0;
end;

procedure TMainForm.SaveProduct(Sender: TObject);
var Price: Currency; Stock: Integer;
begin
  if (Trim(CodeEdit.Text) = '') or (Trim(NameEdit.Text) = '') or
    not TryStrToCurr(PriceEdit.Text, Price) then
    raise Exception.Create('Informe codigo, nome e preco valido.');
  if (Price < 0) or (Price > 1000000) or
    not TryStrToInt(StockEdit.Text, Stock) then
    raise Exception.Create('Preco ou estoque invalido.');
  if Stock < 0 then raise Exception.Create('O estoque nao pode ser negativo.');
  DB.Connection.ExecSQL('INSERT INTO products(code,name,price_cents,stock) VALUES(?,?,?,?)',
    [Trim(CodeEdit.Text), Trim(NameEdit.Text), Int64(Round(Price * 100)), Stock]);
  RefreshData;
  CodeEdit.Clear; NameEdit.Clear; PriceEdit.Clear; StockEdit.Clear;
end;

procedure TMainForm.SaveCustomer(Sender: TObject);
begin
  if Trim(CustomerName.Text) = '' then raise Exception.Create('Informe o nome.');
  DB.Connection.ExecSQL('INSERT INTO customers(name,document,phone) VALUES(?,?,?)',
    [Trim(CustomerName.Text), Trim(DocumentEdit.Text), Trim(PhoneEdit.Text)]);
  RefreshData;
  CustomerName.Clear; DocumentEdit.Clear; PhoneEdit.Clear;
end;

procedure TMainForm.AddItem(Sender: TObject);
var Q: TFDQuery; Item: TCartItem; I, Quantity, Reserved: Integer;
begin
  if not TryStrToInt(QuantityEdit.Text, Quantity) then
    raise Exception.Create('Informe uma quantidade inteira.');
  if (Quantity <= 0) or (Quantity > 1000000) then
    raise Exception.Create('Quantidade fora do intervalo permitido.');
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB.Connection;
    Q.SQL.Text := 'SELECT * FROM products WHERE code = :code';
    Q.ParamByName('code').AsString := Trim(SaleCode.Text);
    Q.Open;
    if Q.Eof then raise Exception.Create('Produto nao encontrado.');
    Item.ProductID := Q.FieldByName('id').AsInteger;
    Reserved := 0;
    for I := 0 to Cart.Count - 1 do
      if Cart[I].ProductID = Item.ProductID then Inc(Reserved, Cart[I].Quantity);
    if Int64(Reserved) + Quantity > Q.FieldByName('stock').AsInteger then
      raise Exception.Create('Estoque insuficiente.');
    Item.Name := Q.FieldByName('name').AsString;
    Item.UnitCents := Q.FieldByName('price_cents').AsLargeInt;
    Item.Quantity := Quantity;
    Cart.Add(Item);
  finally Q.Free; end;
  RenderCart;
  SaleCode.Clear;
  SaleCode.SetFocus;
end;

procedure TMainForm.RenderCart;
var I: Integer; Total: Int64;
begin
  Grid.RowCount := 2;
  for I := 0 to 3 do Grid.Cells[I, 1] := '';
  if Cart.Count > 0 then Grid.RowCount := Cart.Count + 1;
  Total := 0;
  for I := 0 to Cart.Count - 1 do
  begin
    Grid.Cells[0, I+1] := Cart[I].Name;
    Grid.Cells[1, I+1] := IntToStr(Cart[I].Quantity);
    Grid.Cells[2, I+1] := FormatFloat('0.00', Cart[I].UnitCents / 100);
    Grid.Cells[3, I+1] := FormatFloat('0.00', Cart[I].UnitCents * Cart[I].Quantity / 100);
    Inc(Total, Cart[I].UnitCents * Cart[I].Quantity);
  end;
  TotalLabel.Caption := 'Total: R$ ' + FormatFloat('0.00', Total / 100);
end;

procedure TMainForm.RemoveItem(Sender: TObject);
begin
  if (Grid.Row > 0) and (Grid.Row <= Cart.Count) then Cart.Delete(Grid.Row - 1);
  RenderCart;
end;

procedure TMainForm.FinishSale(Sender: TObject);
var
  Item: TCartItem;
  Total, SaleID: Int64;
  Q: TFDQuery;
  Lines: TStringList;
begin
  if Cart.Count = 0 then raise Exception.Create('Adicione produtos a venda.');
  if MessageDlg('Confirmar venda e baixar estoque?', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;
  Total := 0;
  for Item in Cart do Inc(Total, Item.UnitCents * Item.Quantity);
  Lines := TStringList.Create;
  try
    DB.Connection.StartTransaction;
    try
      Q := DB.Query('SELECT NEXT VALUE FOR sale_id_seq AS id FROM RDB$DATABASE');
      try SaleID := Q.FieldByName('id').AsLargeInt; finally Q.Free; end;
      if CustomerCombo.ItemIndex > 0 then
        DB.Connection.ExecSQL('INSERT INTO sales(id,customer_id,total_cents) VALUES(?,?,?)',
          [SaleID, NativeInt(CustomerCombo.Items.Objects[CustomerCombo.ItemIndex]), Total])
      else
        DB.Connection.ExecSQL('INSERT INTO sales(id,total_cents) VALUES(?,?)', [SaleID, Total]);
      Lines.Add('COMPROVANTE DE VENDA - SEM VALOR FISCAL');
      Lines.Add('Venda: ' + IntToStr(SaleID));
      Lines.Add('Data: ' + DateTimeToStr(Now));
      Lines.Add('Cliente: ' + CustomerCombo.Text);
      Lines.Add('');
      for Item in Cart do
      begin
        if DB.Connection.ExecSQL(
          'UPDATE products SET stock=stock-? WHERE id=? AND stock>=?',
          [Item.Quantity, Item.ProductID, Item.Quantity]) <> 1 then
          raise Exception.Create('Estoque insuficiente. Venda nao gravada.');
        DB.Connection.ExecSQL('INSERT INTO sale_items(sale_id,product_id,name,quantity,unit_cents)' +
          ' VALUES(?,?,?,?,?)', [SaleID, Item.ProductID, Item.Name, Item.Quantity, Item.UnitCents]);
        Lines.Add(Format('%d x %s - R$ %.2f',
          [Item.Quantity, Item.Name, Item.Quantity * Item.UnitCents / 100]));
      end;
      Lines.Add('');
      Lines.Add('TOTAL: R$ ' + FormatFloat('0.00', Total / 100));
      DB.Connection.Commit;
    except
      if DB.Connection.InTransaction then DB.Connection.Rollback;
      raise;
    end;
    Cart.Clear;
    Receipt.Lines.Assign(Lines);
    RenderCart;
    RefreshData;
    ShowMessage('Venda gravada. Comprovante disponivel na ultima aba.');
  finally Lines.Free; end;
end;

procedure TMainForm.PrintReceipt(Sender: TObject);
var D: TPrintDialog; I, Y, Step: Integer;
begin
  if Receipt.Lines.Count = 0 then raise Exception.Create('Finalize uma venda primeiro.');
  D := TPrintDialog.Create(Self);
  try
    if not D.Execute then Exit;
    Printer.Title := 'Comprovante sem valor fiscal';
    Printer.BeginDoc;
    try
      Printer.Canvas.Font.Name := 'Courier New';
      Printer.Canvas.Font.Size := 10;
      Step := Printer.Canvas.TextHeight('Ag') + 5;
      Y := Step;
      for I := 0 to Receipt.Lines.Count - 1 do
      begin
        if Y + Step > Printer.PageHeight then
        begin
          Printer.NewPage;
          Y := Step;
        end;
        Printer.Canvas.TextOut(Step, Y, Receipt.Lines[I]);
        Inc(Y, Step);
      end;
      Printer.EndDoc;
    except
      Printer.Abort;
      raise;
    end;
  finally D.Free; end;
end;

end.
