program OBD2App;

uses
  System.StartUpCopy,
  FMX.Forms,
  Principal.Obd2 in 'Principal.Obd2.pas' {frmPrincipal};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
