# HP Color LaserJet Pro M252n on EHCI usb 1-1 (03f0:3c2a, serial VNC3J02356).
# Native POSTSCRIPT/PDF. CUPS talks libusb; services.printing blacklists usblp.
# Keep the printer on USB2/EHCI — do not load uhci_hcd to "find" it.
{userSettings, ...}: {
  services.printing.enable = true;

  users.users.${userSettings.username}.extraGroups = [
    "lp"
    "lpadmin"
  ];

  hardware.printers.ensureDefaultPrinter = "HP_M252n";
  hardware.printers.ensurePrinters = [
    {
      name = "HP_M252n";
      location = "USB";
      description = "HP Color LaserJet Pro M252n";
      deviceUri = "usb://HP/Color%20LaserJet%20Pro%20M252n?serial=VNC3J02356";
      model = "drv:///sample.drv/generic.ppd";
      ppdOptions = {
        PageSize = "A4";
      };
    }
  ];
}
