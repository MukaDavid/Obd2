unit Principal.Obd2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Forms, FMX.Types, FMXTee.Engine, FMXTee.Series, FMXTee.Procs, FMXTee.Chart, FMX.Controls, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Layouts, System.Bluetooth, FMX.TabControl, FMX.ListBox, System.Bluetooth.Components, FMX.Dialogs, FMX.ScrollBox, FMX.Memo, FMX.Objects;

type
  TfrmPrincipal = class(TForm)
    Layout2: TLayout;
    Chart1: TChart;
    Timer1: TTimer;
    Bluetooth1: TBluetooth;
    Layout4: TLayout;
    cbxDevice: TComboBox;
    btnListarDispositivos: TButton;
    TabControl1: TTabControl;
    TabConexao: TTabItem;
    TabGraficos: TTabItem;
    Layout5: TLayout;
    lblConectado: TLabel;
    btnConectar: TButton;
    Label2: TLabel;
    Layout1: TLayout;
    Image1: TImage;
    imgPonteiro: TImage;
    Layout3: TLayout;
    lblTemperatura: TLabel;
    Chart2: TChart;
    SeriesRpm: TAreaSeries;
    SeriesSpeed: TAreaSeries;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Chart3: TChart;
    Series1: TPieSeries;
    lblAbertura: TLabel;
    StyleBook1: TStyleBook;
    Label5: TLabel;
    Rectangle1: TRectangle;
    Rectangle2: TRectangle;
    procedure Timer1Timer(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
    procedure btnListarDispositivosClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FSocket : TBluetoothSocket;
    FSequencia : integer;
    procedure ListarDispositivosPareadosNoCombo;
    function ObterDispositivoPeloNome(pNameDevice: String): TBluetoothDevice;
    function ConectarDispositivo(pNameDevice: String): boolean;
    procedure IniciarSeriesChart;
    procedure AdicionarValorNaSerie(pSerie: TCustomSeries; pValor: Double);
    procedure AjustarPonteiro(pTemperatura:Double);
    procedure AjustarBorboleta(Percentual:Double);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

const
  UUID = '{00001101-0000-1000-8000-00805F9B34FB}';

implementation

{$R *.fmx}
{$R *.NmXhdpiPh.fmx ANDROID}

procedure TfrmPrincipal.AdicionarValorNaSerie(pSerie: TCustomSeries; pValor: Double);
begin

  var lPosAtual := pSerie.YValues.Count - 1;
  for var li := 0 to lPosAtual - 1 do
  begin
    pSerie.YValue[li] := pSerie.YValue[li+1];
  end;

  pSerie.YValue[lPosAtual] := pValor;
end;

procedure TfrmPrincipal.AjustarBorboleta(Percentual: Double);
begin
  Series1.YValue[1] := Percentual;
  Series1.YValue[0] := 100 - Percentual;
  lblAbertura.Text := FormatFloat('0',Percentual)+'%';
end;

procedure TfrmPrincipal.AjustarPonteiro(pTemperatura: Double);
var
  lAngulo: Double;
begin
  if (pTemperatura - 77) < -35 then
    lAngulo := -35
  else if (pTemperatura - 77) > 45 then
    lAngulo := 45
  else
    lAngulo := pTemperatura - 77;

  imgPonteiro.RotationAngle := lAngulo;
  lblTemperatura.Text := FormatFloat('00.0',pTemperatura)+'ºC';
end;

procedure TfrmPrincipal.btnConectarClick(Sender: TObject);
begin
  lblConectado.Text := 'Desconectado';
  if (cbxDevice.Selected.Text <> '') then
  begin
    if ConectarDispositivo(cbxDevice.Selected.Text) then
      lblConectado.Text := 'Conectado'
    else
      lblConectado.Text := 'Desconectado';
    end
  else
    ShowMessage('Selecione um dispositivo');

end;

procedure TfrmPrincipal.btnListarDispositivosClick(Sender: TObject);
begin
  ListarDispositivosPareadosNoCombo;
end;

function TfrmPrincipal.ConectarDispositivo(pNameDevice: String): boolean;
begin
  Result := False;
  var lDevice := ObterDispositivoPeloNome(pNameDevice);
  if lDevice <> nil then
  begin
    FSocket := lDevice.CreateClientSocket(StringToGUID(UUID), True);
    if FSocket <> nil then
    begin
      FSocket.Connect;
      Result := FSocket.Connected;
    end;
  end;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  IniciarSeriesChart;
  ListarDispositivosPareadosNoCombo;
end;

procedure TfrmPrincipal.IniciarSeriesChart;
begin
  //Series1.YValue[li-1] := Series1.YValue[li];
  for var li := 0 to 29 do
  begin
    SeriesRpm.Add(0);
    SeriesSpeed.Add(0);
  end;

  Series1.Add(0,'',$FF404040);
  Series1.Add(100,'',$FFFA0B8C);

end;

procedure TfrmPrincipal.ListarDispositivosPareadosNoCombo;
begin
  cbxDevice.Clear;
  for var lDevice in Bluetooth1.PairedDevices do
  begin
    cbxDevice.Items.Add(lDevice.DeviceName);
  end;
end;

function TfrmPrincipal.ObterDispositivoPeloNome(pNameDevice: String): TBluetoothDevice;
begin
  Result := nil;
  for var lDevice in Bluetooth1.PairedDevices do
  begin
    if lDevice.DeviceName = pNameDevice then
    begin
      Result := lDevice;
    end;
  end;
end;

procedure TfrmPrincipal.Timer1Timer(Sender: TObject);
var
  lData : TBytes;
  lRegistros : TStringList;
  llinha, lSensor, lValor: string;
begin
  if (FSocket <> nil) and (FSocket.Connected) then
  begin
    lData := FSocket.ReceiveData;
    lRegistros := TStringList.Create;
    lRegistros.Text := trim(TEncoding.ANSI.GetString(lData));

    if lRegistros.Text <> '' then
    begin

      for var li := 0 to lRegistros.Count - 1 do
      begin
        llinha := trim(lRegistros[li]);
        //ListBox1.Items.Add(llinha);
        FSequencia := FSequencia + 1;
        Label2.Text := FSequencia.ToString;
        lSensor := copy(llinha,0,2);
        lValor  := StringReplace(copy(llinha,3,length(llinha)-2),'.',',',[]);

        if lSensor = '0C' then
        begin
          AdicionarValorNaSerie(SeriesRpm,StrToFloat(lValor));
        end;

        if lSensor = '0D' then
        begin
          AdicionarValorNaSerie(SeriesSpeed,StrToFloat(lValor));
        end;

        if lSensor = '05' then
        begin
          AjustarPonteiro(StrToFloat(lValor));
        end;

        if lSensor = '11' then
        begin
          AjustarBorboleta(StrToFloat(lValor));
        end;

      end;
    end;
  end;
end;

end.
