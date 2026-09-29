unit lbc_render; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  zint, lbc_helper;

function render_plot_create_line(x, y, width, length: Single): PointerTo_zint_render_line;
function render_plot_add_line(symbol: PointerTo_zint_symbol; line: PointerTo_zint_render_line; last_line: PointerTo_PointerTo_zint_render_line): Integer;
function render_plot_create_ring(x, y, radius, line_width: Single): PointerTo_zint_render_ring;
function render_plot_add_ring(symbol: PointerTo_zint_symbol; ring: PointerTo_zint_render_ring; last_ring: PointerTo_PointerTo_zint_render_ring): Integer;
function render_plot_create_hexagon(x, y: Single): PointerTo_zint_render_hexagon;
function render_plot_add_hexagon(symbol: PointerTo_zint_symbol; hexagon: PointerTo_zint_render_hexagon; last_hexagon: PointerTo_PointerTo_zint_render_hexagon): Integer;
function render_plot_add_string(symbol: PointerTo_zint_symbol; text: PBYTE; x, y, fsize, width: Single; last_string: PointerTo_PointerTo_zint_render_string): Integer;
function render_plot(symbol: PointerTo_zint_symbol; width: Single; height: Single): Integer;

implementation

function render_plot(symbol: PointerTo_zint_symbol; width: Single; height: Single): Integer;
var
  render: PointerTo_zint_render;
  last_line: PointerTo_zint_render_line = nil;
  line: PointerTo_zint_render_line = nil;
  last_string: PointerTo_zint_render_string = nil;
  last_ring: PointerTo_zint_render_ring = nil;
  ring: PointerTo_zint_render_ring = nil;
  {%H-}last_hexagon: PointerTo_zint_render_hexagon = nil;
  {%H-}hexagon: PointerTo_zint_render_hexagon = nil;
  this_row: Integer;
  latch: Integer;
  block_width: Integer;
  r: Integer;
  i: Integer;
  row_posn: Single = 0.0;
  row_height: Single = 0.0;
  preset_height: Single = 0.0;
  large_bar_height: Single = 0.0;
  textwidth: Single = 0.0;
  textpos: Single = 0.0;
  addon_width_x: Integer;
  main_symbol_width_x: Integer;
  textdone: Integer;
  yoffset: Integer;
  xoffset: Integer;
  text_height: Integer;
  text_offset: Integer;
  textpart: array[0..9] of Char;
  addon: array[0..5] of Char;
  total_area_width_x: Integer;
  total_symbol_width_x: Integer;
  symbol_lead_in: Integer;
  large_bar_count: Integer;
  addon_text_posn: Single;
  default_text_posn: Single;
  scaler: Single;
  //locale: pchar = nil;
  hide_text: Boolean = false;
  required_aspect: Single;
  symbol_aspect: Single = 1.0;
  x_dimension: Single;
  upceanflag: Integer = 0;
  addon_latch: Integer = 0;
begin
  Result := 0;
  
  // Allocate memory for the rendered version
  GetMem(Symbol^.rendered,sizeof(zint_render));
  render:=Symbol^.rendered;
  render^.lines := nil;
  render^.strings := nil;
  render^.rings := nil;
  render^.hexagons := nil;
//  locale := setlocale (LC_ALL, 'C');

  row_height := 0;
  textdone := 0;
  textpos := 0.0;
  main_symbol_width_x := symbol^.width;
  addon[0] := #0;
  strcpy(addon, '');
  symbol_lead_in := 0;
  addon_text_posn := 0.0;
  addon_width_x := 0;
  
  { Determine if there will be any addon texts and text height }
  latch := 0;
  r := 0;
  // Isolate add-on text 
  if is_extendable (symbol^.symbology) then
  begin
    for i := 0 to sysutils.strlen(@symbol^.text[0])-1 do
    begin
      if latch = 1 then
      begin
        addon[r] := char(symbol^.text[i]);
        Inc(r);
      end;
      if char(symbol^.text[i]) = '+' then
      begin
        latch := 1;
      end;
    end;
  end;
  addon[r] := #0;
  
  if (symbol^.show_hrt=0) or (sysutils.strlen(@symbol^.text[0]) = 0) then
  begin
    hide_text := true;
    text_offset := 0;
    text_height := 0;
  end else begin
    text_height := symbol^.font_height;
    text_offset := 2;
  end;
  
  { Calculate the width of the barcode, especially if there are any extra
    borders or white space to add. }
  while not (module_is_set(symbol, symbol^.rows - 1, symbol_lead_in)) do
    Inc(symbol_lead_in);
  
  // Certain symbols need whitespace otherwise characters get chopped off the sides
  if ((symbol^.symbology = BARCODE_EANX) and (symbol^.rows = 1)) or 
     (symbol^.symbology = BARCODE_EANX_CC) or 
     (symbol^.symbology = BARCODE_ISBNX) then
  begin
    case sysutils.strlen(@symbol^.text[0]) of
      13, 16, 19:
        begin
          if symbol^.whitespace_width = 0 then
            symbol^.whitespace_width := 10;
          main_symbol_width_x := 96 + symbol_lead_in;
          upceanflag := 13;
        end;
      2:
        begin
          main_symbol_width_x := 22 + symbol_lead_in;
          upceanflag := 2;
        end;
      5:
        begin
          main_symbol_width_x := 49 + symbol_lead_in;
          upceanflag := 5;
        end;
      otherwise
        begin
          main_symbol_width_x := 68 + symbol_lead_in;
          upceanflag := 8;
        end;
    end;
    case sysutils.strlen(@symbol^.text[0]) of
      11, 16: addon_width_x := 31;    // EAN-2 add-on
      14, 19: addon_width_x := 58;    // EAN-5 add-on
    end;
  end;

  if ((symbol^.symbology = BARCODE_UPCA) and (symbol^.rows = 1)) or 
      (symbol^.symbology = BARCODE_UPCA_CC) then
  begin
    upceanflag := 12;
    if symbol^.whitespace_width < 10 then
    begin
      symbol^.whitespace_width := 10;
      main_symbol_width_x := 96 + symbol_lead_in;
    end;
    case sysutils.strlen (@symbol^.text[0]) of
      15: addon_width_x := 31;     // EAN-2 add-on
      18: addon_width_x := 58;     // EAN-5 add-on
    end;
  end;

  if ((symbol^.symbology = BARCODE_UPCE)) and (symbol^.rows = 1) or 
      (symbol^.symbology = BARCODE_UPCE_CC) then
  begin
    upceanflag := 6;
    if symbol^.whitespace_width = 0 then
    begin
      symbol^.whitespace_width := 10;
      main_symbol_width_x := 51 + symbol_lead_in;
    end;
    case sysutils.strlen (@symbol^.text[0]) of
      11: addon_width_x := 31;    // EAN-2 add-on
      14: addon_width_x := 58;    // EAN-5 add-on
    end;
  end;

  total_symbol_width_x := main_symbol_width_x + addon_width_x;
  total_area_width_x := total_symbol_width_x + 2*(symbol^.border_width + symbol^.whitespace_width);

  xoffset := symbol^.border_width + symbol^.whitespace_width;
  yoffset := symbol^.border_width;

  { Determine if height should be overridden }
  large_bar_count := 0;
  preset_height := 0.0;
  i := 0;
  while i < symbol^.rows do
  begin
    preset_height := preset_height + symbol^.row_height[i];
    if symbol^.row_height[i] = 0 then
    begin
      Inc(large_bar_count);
    end;
    Inc (i);
  end;

  if large_bar_count = 0 then
  begin
    if height = 0 then
      required_aspect := 1.0
    else
      required_aspect := width / height;
    symbol_aspect := (total_symbol_width_x + 2*xoffset) / (preset_height + 2*yoffset + text_offset + text_height);
    symbol^.height := trunc(preset_height);
    if required_aspect > symbol_aspect then
    begin
      // the area is too wide
      if symbol^.scale > 0 then
        scaler := symbol^.scale
      else
        scaler := height / (preset_height + 2*yoffset + text_offset + text_height);
      render^.width := symbol_aspect * height;
      render^.height := height;
    end else begin
      // the area is too high
      if symbol^.scale > 0 then
        scaler := symbol^.scale
      else
        scaler := width / (total_symbol_width_x + 2*xoffset);
      render^.width := width;
      render^.height := width / symbol_aspect;
    end;
    large_bar_height := 0;
  end else begin
    if symbol^.scale > 0 then
      scaler := symbol^.scale
    else
      scaler := width / (total_symbol_width_x + 2*xoffset);
    if scaler = 0 then 
    begin
      Result := ERROR_TOO_LONG;   // avoid divide-by-zero error
      exit;
    end;
//    symbol^.height := Trunc((height / scaler) - (2*yoffset + text_offset + text_height));  // -- orig
    symbol^.height := Trunc(((height - text_height - text_offset) / scaler) - 2*yoffset);
    render^.width := width;
    render^.height := height;
    large_bar_height := (symbol^.height - preset_height) / large_bar_count;
  end;
                             {
  if ((symbol^.output_options and BARCODE_BOX) <> 0) or ((symbol^.output_options and BARCODE_BIND) <> 0) then
    default_text_posn := (symbol^.height + text_offset + 2*symbol^.border_width) * scaler
  else 
    default_text_posn := (symbol^.height + text_offset + symbol^.border_width) * scaler;
}

  if symbol^.output_options and (BARCODE_BOX or BARCODE_BIND) <> 0 then
   default_text_posn := (symbol^.height + 2*symbol^.border_width) * scaler + text_offset
  else 
   default_text_posn := (symbol^.height + symbol^.border_width) * scaler + text_offset; 

  x_dimension := render^.width / total_area_width_x;
  x_dimension := x_dimension / GL_CONST;


  { Set minimum size of symbol }
  
  // Barcode must be at least 2 mm high and 2 mm across
  if render^.height < ((x_dimension * (2*symbol^.border_width + text_offset + text_height)) + 2.0) * GL_CONST then
    render^.height := ((x_dimension * (2*symbol^.border_width + text_offset + text_height)) + 2.0) * GL_CONST;
  if render^.width < 2.0 * GL_CONST then
    render^.width := 2.0 * GL_CONST;

  // The minimum X-dimension of Codabar is 0.191 mm. The minimum bar height is 5 mm 
  if symbol^.symbology = BARCODE_CODABAR then
  begin
    if x_dimension < 0.191 then
      render^.width := 0.191 * GL_CONST * total_area_width_x;
    if render^.height < ((x_dimension * (2*symbol^.border_width + text_offset + text_height)) + 5.0) * GL_CONST then
      render^.height := ((x_dimension * (2*symbol^.border_width + text_offset + text_height)) + 5.0) * GL_CONST;
  end;

  // The minimum X-dimension of Code 49 is 0.191 mm 
  if symbol^.symbology = BARCODE_CODE49 then
  begin
    if x_dimension < 0.191 then
    begin
      render^.width := 0.191 * GL_CONST * total_area_width_x;
      render^.height := render^.width / symbol_aspect;
    end;
  end;

  // The X-dimension of UPC/EAN symbols is fixed at 0.330mm
  // NOTE: This code will need adjustment before it correctly deals with composite symbols
  if upceanflag <> 0 then
  begin
    render^.width := 0.330 * GL_CONST * total_area_width_x;
    // The height is also fixed.
    case upceanflag of
      6, 12, 13: 
        // UPC-A, UPC-E and EAN-13:  Height of bars should be 22.85 mm 
        render^.height := ((0.330 * ((2 * symbol^.border_width) + text_offset + text_height)) + 22.85) * GL_CONST;
      8: 
        // EAN-8:  Height of bars should be 18.23 mm 
        render^.height := ((0.330 * ((2 * symbol^.border_width) + text_offset + text_height)) + 18.23) * GL_CONST;
      otherwise  
      // EAN-2 and EAN-5: Height of bars should be 21.10 mm
        render^.height := ((0.330 * ((2 * symbol^.border_width) + text_offset + text_height)) + 21.10) * GL_CONST;
    end;
  end;

  // The size of USPS Intelligent Mail barcode is fixed
  if symbol^.symbology = BARCODE_ONECODE then
  begin
    render^.width := 0.508 * GL_CONST * total_area_width_x;
    render^.height := 4.064 * GL_CONST;
  end;

  // The sizes of PostNet and PLANET are fized 
  if (symbol^.symbology = BARCODE_POSTNET) or (symbol^.symbology = BARCODE_PLANET) then
  begin
    render^.width := 0.508 * GL_CONST * total_area_width_x;
    render^.height := 2.921 * GL_CONST;
  end;

  // Australia Post use the same sizes as USPS
  if (symbol^.symbology = BARCODE_AUSPOST) or 
     (symbol^.symbology = BARCODE_AUSREPLY) or 
     (symbol^.symbology = BARCODE_AUSROUTE) or 
     (symbol^.symbology = BARCODE_AUSREDIRECT) then
  begin
    render^.width := 0.508 * GL_CONST * total_area_width_x;
    render^.height := 4.064 * GL_CONST;
  end;

  // Royal Mail and KIX Code uses 22 bars per inch
  if (symbol^.symbology = BARCODE_RM4SCC) or (symbol^.symbology = BARCODE_KIX) then
  begin
    render^.width := 0.577 * GL_CONST * total_area_width_x;
    render^.height := 5.22 * GL_CONST;
  end;

  // Maxicode is a fixed size
  if symbol^.symbology = BARCODE_MAXICODE then
  begin
    scaler := GL_CONST;  // Converts from millimeters to the scale used by glabels
    render^.width := 28.16 * scaler;
    render^.height := 26.86 * scaler;
    
    // Central bullseye pattern
    ring := render_plot_create_ring (13.64 * scaler, 13.43 * scaler, 0.85 * scaler, 0.67 * scaler);
    render_plot_add_ring (symbol, ring, @last_ring);
    ring := render_plot_create_ring (13.64 * scaler, 13.43 * scaler, 2.20 * scaler, 0.67 * scaler);
    render_plot_add_ring (symbol, ring, @last_ring);
    ring := render_plot_create_ring (13.64 * scaler, 13.43 * scaler, 3.54 * scaler, 0.67 * scaler);
    render_plot_add_ring (symbol, ring, @last_ring);
    
    // Hexagons
    for r := 0 to symbol^.rows-1 do
    begin
      for i := 0 to symbol^.width-1 do
        if module_is_set(symbol,r, i) then
        begin
          if r and 1 <> 0 then
            hexagon := render_plot_create_hexagon((i*0.88 + 1.76) * scaler, (r*0.76 + 0.76)*scaler)
          else
            hexagon := render_plot_create_hexagon((i*0.88 + 1.32) * scaler, (r*0.76 + 0.76)*scaler);
        end;
    end;
  end 
  else 
  begin
    // Everything else uses rectangles (or squares). 
    // Works from the bottom of the symbol up
    addon_latch := 0;
    for r := 0 to symbol^.rows-1 do
    begin
      this_row := r;
      if symbol^.row_height[this_row] = 0 then
      begin
        row_height := large_bar_height;
      end else begin
        row_height := symbol^.row_height[this_row];
      end;
      row_posn := 0;
      i := 0;
      while i < r do
      begin
        if symbol^.row_height[i] = 0 then
        begin
          row_posn := row_posn + large_bar_height;
        end else begin
          row_posn := row_posn + (symbol^.row_height[i]);
        end;
        Inc (i);
      end;
      row_posn := row_posn + yoffset;
      
      i := 0;
      if module_is_set (symbol, this_row, 0) then
        latch := 1
      else 
        latch := 0;
      
      repeat
        block_width := 0;
        repeat
          Inc(block_width);
        until (i + block_width >= symbol^.width) or (module_is_set (symbol, this_row, i + block_width) <> module_is_set (symbol, this_row, i));
        if (addon_latch = 0) and (r = (symbol^.rows - 1)) and (i > main_symbol_width_x) then
        begin
          addon_text_posn := row_posn * scaler;
          addon_latch := 1;
        end;
        if latch = 1 then
        begin
          // a bar
          if addon_latch = 0 then
            line := render_plot_create_line ((i + xoffset) * scaler, (row_posn) * scaler, block_width * scaler, row_height * scaler)
          else 
            line := render_plot_create_line ((i + xoffset) * scaler, (row_posn + 10.0) * scaler, block_width * scaler, (row_height - 5.0) * scaler);
          latch := 0;
          render_plot_add_line (symbol, line, @last_line);
        end else 
          // a space
          latch := 1;
        inc(i, block_width);
      until (i >= symbol^.width);
    end;
  end;
  // That's done the actual data area, everything else is human-friendly

  // Add the text
  xoffset := xoffset - symbol_lead_in;
  row_posn := (row_posn + large_bar_height) * scaler;

  if not hide_text then
  begin
    // guard bar extensions and text formatting for EAN-8
    if upceanflag = 8 then
    begin
      i := 0;
      line := symbol^.rendered^.lines;
      while line <> nil do
      begin
        case i of
          0, 1, 10, 11, 20, 21: 
            line^.length := line^.length + 5.0 * scaler;
          otherwise
            ;
        end;
        Inc (i);
        line := line^.next;
      end;
      
      for i := 0 to 3 do
        textpart[i] := char(symbol^.text[i]);
      textpart[4] := #0;
      textpos := 17;
      textwidth := 4.0 * 8.5;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset) * scaler, default_text_posn, 11.0 * scaler, textwidth * scaler, @last_string);
      
      for i := 0 to 3 do
        textpart[i] := char(symbol^.text[i + 4]);
      textpart[4] := #0;
      textpos := 50;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset) * scaler, default_text_posn, 11.0 * scaler, textwidth * scaler, @last_string);
      textdone := 1;
      
      case strlen(addon) of
        2:
          begin
            textpos := xoffset + 86;
            textwidth := 2.0 * 8.5;
            render_plot_add_string(symbol, PByte(@addon[0]), textpos * scaler, addon_text_posn * scaler, 11.0 * scaler, textwidth * scaler, @last_string);
          end;
        5:
          begin
            textpos := xoffset + 100;
            textwidth := 5.0 * 8.5;
            render_plot_add_string(symbol, PByte(@addon[0]), textpos * scaler, addon_text_posn * scaler, 11.0 * scaler, textwidth * scaler, @last_string);
          end;
      end;
    end;

    // guard bar extensions and text formatting for EAN-13
    if upceanflag = 13 then
    begin
      i := 0;
      line := symbol^.rendered^.lines;
      while line <> nil do
      begin
        if (i in [0, 1, 14, 15, 28, 29]) then
          line^.length := line^.length + 5.0*scaler;
        inc(i);
        line := line^.next;
      end;
      
      textpart[0] := char(symbol^.text[0]);
      textpart[1] := #0;
      textpos := -5;
      textwidth := 8.5;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset)*scaler, default_text_posn, 11.0*scaler, textwidth*scaler, @last_string);
      
      for i := 0 to 5 do
        textpart[i] := char(symbol^.text[i + 1]);
      textpart[6] := #0;
      textpos := 25;
      textwidth := 8.5;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset)*scaler, default_text_posn, 11.0*scaler, textwidth*scaler, @last_string);
      
      for i := 0 to 5 do
        textpart[i] := char(symbol^.text[i + 7]);
      textpart[6] := #0;
      textpos := 72;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset)*scaler, default_text_posn, 11.0*scaler, textwidth*scaler, @last_string);
      textdone := 1;
      
      case strlen(addon) of
        2:
          begin
            textpos := xoffset + 114;
            textwidth := 2.0 * 8.5;
            render_plot_add_string(symbol, PByte(@addon[0]), textpos*scaler, addon_text_posn*scaler, 11.0*scaler, textwidth*scaler, @last_string);
          end;
        5:
          begin
            textpos := xoffset + 128;
            textwidth := 5.0 * 8.5;
            render_plot_add_string(symbol, PByte(@addon[0]), textpos*scaler, addon_text_posn*scaler, 11.0*scaler, textwidth*scaler, @last_string);
          end;
      end;
    end;

    // guard bar extensions and text formatting for UPCA
    if upceanflag = 12 then
    begin
      i := 0;
      line := symbol^.rendered^.lines;
      while line <> nil do
      begin
        if (i in [0, 1, 2, 3, 14, 15, 26, 27, 28, 29]) then
          line^.length := line^.length + 5.0*scaler;
        Inc (i);
        line := line^.next;
      end;
      
      textpart[0] := char(symbol^.text[0]);
      textpart[1] := #0;
      textpos := -5;
      textwidth := 6.2;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset)*scaler, default_text_posn + 2.0*scaler, 8.0*scaler, textwidth*scaler, @last_string);
      for i := 0 to 4 do
        textpart[i] := char(symbol^.text[i + 1]);
      textpart[5] := #0;
      textpos := 27;
      textwidth := 5.0 * 8.5;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset)*scaler, default_text_posn, 11.0*scaler, textwidth*scaler, @last_string);
      for i := 0 to 5 do
        textpart[i] := char(symbol^.text[i + 6]);
      textpos := 68;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset)*scaler, default_text_posn, 11.0*scaler, textwidth*scaler, @last_string);
      textpart[0] :=char(symbol^.text[11]);
      textpart[1] := #0;
      textpos := 100;
      textwidth := 6.2;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset)*scaler, default_text_posn + 2.0*scaler, 8.0*scaler, textwidth*scaler, @last_string);
      textdone := 1;
      case strlen (addon) of
        2:
          begin
            textpos := xoffset + 116;
            textwidth := 2.0 * 8.5;
            render_plot_add_string(symbol, PByte(@addon[0]), textpos*scaler, addon_text_posn*scaler, 11.0*scaler, textwidth*scaler, @last_string);
          end;
        5:
          begin
            textpos := xoffset + 130;
            textwidth := 5.0 * 8.5;
            render_plot_add_string(symbol, PByte(@addon[0]), textpos*scaler, addon_text_posn*scaler, 11.0*scaler, textwidth*scaler, @last_string);
          end;
      end;
    end;
    
    // guard bar extensions and text formatting for UPCE
    if upceanflag = 6 then
    begin
      i := 0;
      line := symbol^.rendered^.lines;
      while line <> nil do
      begin
        if (i in [0, 1, 14, 15, 16]) then
          line^.length := line^.length + 5.0*scaler;
        Inc(i);
        line := line^.next;
      end;
      
      textpart[0] := char(symbol^.text[0]);
      textpart[1] := #0;
      textpos := -5;
      textwidth := 6.2;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset)*scaler, default_text_posn + 2.0*scaler, 8.0*scaler, textwidth*scaler, @last_string);
      for i := 0 to 5 do
        textpart[i] := char(symbol^.text[i + 1]);
      textpart[6] := #0;
      textpos := 24;
      textwidth := 6.0 * 8.5;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset)*scaler, default_text_posn, 11.0*scaler, textwidth*scaler, @last_string);
      textpart[0] := char(symbol^.text[7]);
      textpart[1] := #0;
      textpos := 55;
      textwidth := 6.2;
      render_plot_add_string(symbol, PByte(@textpart[0]), (textpos + xoffset)*scaler, default_text_posn + 2.0*scaler, 8.0*scaler, textwidth*scaler, @last_string);
      textdone := 1;
      case strlen(addon) of
        2:
          begin
            textpos := xoffset + 70;
            textwidth := 2.0 * 8.5;
            render_plot_add_string(symbol, PByte(@addon[0]), textpos*scaler, addon_text_posn*scaler, 11.0*scaler, textwidth*scaler, @last_string);
          end;
        5:
          begin
            textpos := xoffset + 84;
            textwidth := 5.0 * 8.5;
            render_plot_add_string(symbol, PByte(@addon[0]), textpos*scaler, addon_text_posn*scaler, 11.0*scaler, textwidth*scaler, @last_string);
          end;
      end;
    end;

    // Put normal human readable text at the bottom (and centered)
    if textdone = 0 then
      // calculate start xoffset to center text
      render_plot_add_string(symbol, symbol^.text, ((symbol^.width / 2.0) + xoffset) * scaler, default_text_posn, text_height {9.0 * scaler}, 0.0, @last_string);
  end;

  case symbol^.symbology of
    BARCODE_MAXICODE:
      begin
        //Do nothing...
      end;
    otherwise
      begin
        if (symbol^.output_options and BARCODE_BIND) <> 0 then
        begin
          if (symbol^.rows > 1) and is_stackable(symbol^.symbology) then
          begin
            // row binding
            for r := 1 to symbol^.rows-1 do
            begin
              line := render_plot_create_line(xoffset * scaler, (r*row_height + yoffset - 1) * scaler, symbol^.width * scaler, 2.0*scaler);
              render_plot_add_line(symbol, line, @last_line);
            end;
          end;
        end;
        if (symbol^.output_options and BARCODE_BOX <> 0) or (symbol^.output_options and BARCODE_BIND <> 0) then
        begin
          line := render_plot_create_line(0, 0, (symbol^.width + xoffset + xoffset) * scaler, symbol^.border_width * scaler);
          render_plot_add_line(symbol, line, @last_line);
          line := render_plot_create_line(0, (symbol^.height + symbol^.border_width) * scaler, (symbol^.width + xoffset + xoffset) * scaler, symbol^.border_width * scaler);
          render_plot_add_line(symbol, line, @last_line);
        end;
        if (symbol^.output_options and BARCODE_BOX) <> 0 then
        begin
          line := render_plot_create_line(0, 0, symbol^.border_width * scaler, (symbol^.height + 2*symbol^.border_width) * scaler);
          render_plot_add_line(symbol, line, @last_line);
          line := render_plot_create_line((symbol^.width + xoffset + xoffset - symbol^.border_width) * scaler, 0, symbol^.border_width * scaler, (symbol^.height + 2*symbol^.border_width) * scaler);
          render_plot_add_line(symbol, line, @last_line);
        end;
      end;
  end;
  (*
  if Boolean(locale) then
  begin
    setlocale (LC_ALL, locale);
  end;
  *)

  // store for calling routine
  render^.scale := scaler;
  render^.exact_width := total_area_width_x * scaler; 

  Result := 1;
end;

{ Create a new line with its memory allocated ready for adding to the
  rendered structure.
  This is much quicker than writing out each line manually (in some cases!) }
function render_plot_create_line(x, y, width, length: Single): PointerTo_zint_render_line;
var
  line: PointerTo_zint_render_line;
begin
  line := GetMem (SizeOf (zint_render_line));
  line^.next := nil;
  line^.x := x;
  line^.y := y;
  line^.width := width;
  line^.length := length;
  Result := line;
end;

{ Add the line to the current rendering and update the last line's next value. }
function render_plot_add_line(symbol: PointerTo_zint_symbol; 
  line: PointerTo_zint_render_line; last_line: PointerTo_PointerTo_zint_render_line): Integer;
begin
  if last_line^ <> nil then
  begin
    (last_line^)^.next := line;
  end else begin
    symbol^.rendered^.lines := line;
  end;
  last_line^ := line;
  Result := 1;
end;

function render_plot_create_ring(x: Single; y: Single; radius: Single; line_width: Single): PointerTo_zint_render_ring;
var
  ring: PointerTo_zint_render_ring;
begin
  ring := GetMem (SizeOf (zint_render_ring));
  ring^.next := nil;
  ring^.x := x;
  ring^.y := y;
  ring^.radius := radius;
  ring^.line_width := line_width;
  exit (ring);
end;

function render_plot_add_ring(symbol: PointerTo_zint_symbol; ring: PointerTo_zint_render_ring; last_ring: PointerTo_PointerTo_zint_render_ring): Integer;
begin
  if last_ring^<>nil then
  begin
    (last_ring^)^.next := ring;
  end else begin
    symbol^.rendered^.rings := ring;
  end;
  last_ring^ := ring;
  exit (1);
end;

function render_plot_create_hexagon(x: Single; y: Single): PointerTo_zint_render_hexagon;
var
  hexagon: PointerTo_zint_render_hexagon;
begin
  hexagon := GetMem (SizeOf (zint_render_hexagon));
  hexagon^.next := nil;
  hexagon^.x := x;
  hexagon^.y := y;
  exit (hexagon);
end;

function render_plot_add_hexagon(symbol: PointerTo_zint_symbol; hexagon: PointerTo_zint_render_hexagon; last_hexagon: PointerTo_PointerTo_zint_render_hexagon): Integer;
begin
  if last_hexagon^<>nil then
  begin
    (last_hexagon^)^.next := hexagon;
  end else begin
    symbol^.rendered^.hexagons := hexagon;
  end;
  last_hexagon^ := hexagon;
  exit (1);
end;

{ Add a string structure to the symbol. 
  Coordinates assumed to be from top-center. }
function render_plot_add_string(symbol: PointerTo_zint_symbol; text: PByte; 
  x, y, fsize, width: Single; last_string: PointerTo_PointerTo_zint_render_string): Integer;
var
  pstring: PointerTo_zint_render_string;
begin
  pstring := GetMem (SizeOf(zint_render_string));
  pstring^.next := nil;
  pstring^.x := x;
  pstring^.y := y;
  pstring^.width := width;
  pstring^.fsize := fsize;
  pstring^.length := sysutils.strlen(PChar(text));
  pstring^.text := GetMem(SizeOf (BYTE) * (sysutils.strlen(PChar(text)) + 1));
  strcpy (pchar(pstring^.text), pchar(text));
  if last_string^ <> nil then
    (last_string^)^.next := pstring
  else 
    symbol^.rendered^.strings := pstring;
  last_string^ := pstring;
  Result := 1;
end;

end.

