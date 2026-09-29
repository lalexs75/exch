{  lbc_maxicode.pas - Handles the MaxiCode symbology

  Based on Zint (done by Robin Stuart and the Zint team)
    http://github.com/zint/zint
    
  Refactoring: W. Pamler
} 

unit lbc_MaxiCode;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  Sysutils, zint;
  
function maxicode(ASymbol: PZintSymbol; ASource: String): Integer;

implementation

uses
  Types, Math, lbc_helper, lbc_reedsolomon;
  
const 
  { ISO/IEC 16023 Figure 5 - MaxiCode Module Sequence } { 30 x 33 data grid }  
  MaxiGrid: array[0..989] of Integer = ( 
    122, 121, 128, 127, 134, 133, 140, 139, 146, 145, 152, 151, 158, 157, 164, 163, 170, 169, 176, 175, 182, 181, 188, 187, 194, 193, 200, 199, 0, 0,
    124, 123, 130, 129, 136, 135, 142, 141, 148, 147, 154, 153, 160, 159, 166, 165, 172, 171, 178, 177, 184, 183, 190, 189, 196, 195, 202, 201, 817, 0,
    126, 125, 132, 131, 138, 137, 144, 143, 150, 149, 156, 155, 162, 161, 168, 167, 174, 173, 180, 179, 186, 185, 192, 191, 198, 197, 204, 203, 819, 818,
    284, 283, 278, 277, 272, 271, 266, 265, 260, 259, 254, 253, 248, 247, 242, 241, 236, 235, 230, 229, 224, 223, 218, 217, 212, 211, 206, 205, 820, 0,
    286, 285, 280, 279, 274, 273, 268, 267, 262, 261, 256, 255, 250, 249, 244, 243, 238, 237, 232, 231, 226, 225, 220, 219, 214, 213, 208, 207, 822, 821,
    288, 287, 282, 281, 276, 275, 270, 269, 264, 263, 258, 257, 252, 251, 246, 245, 240, 239, 234, 233, 228, 227, 222, 221, 216, 215, 210, 209, 823, 0,
    290, 289, 296, 295, 302, 301, 308, 307, 314, 313, 320, 319, 326, 325, 332, 331, 338, 337, 344, 343, 350, 349, 356, 355, 362, 361, 368, 367, 825, 824,
    292, 291, 298, 297, 304, 303, 310, 309, 316, 315, 322, 321, 328, 327, 334, 333, 340, 339, 346, 345, 352, 351, 358, 357, 364, 363, 370, 369, 826, 0,
    294, 293, 300, 299, 306, 305, 312, 311, 318, 317, 324, 323, 330, 329, 336, 335, 342, 341, 348, 347, 354, 353, 360, 359, 366, 365, 372, 371, 828, 827,
    410, 409, 404, 403, 398, 397, 392, 391, 80, 79, 0, 0, 14, 13, 38, 37, 3, 0, 45, 44, 110, 109, 386, 385, 380, 379, 374, 373, 829, 0,
    412, 411, 406, 405, 400, 399, 394, 393, 82, 81, 41, 0, 16, 15, 40, 39, 4, 0, 0, 46, 112, 111, 388, 387, 382, 381, 376, 375, 831, 830,
    414, 413, 408, 407, 402, 401, 396, 395, 84, 83, 42, 0, 0, 0, 0, 0, 6, 5, 48, 47, 114, 113, 390, 389, 384, 383, 378, 377, 832, 0,
    416, 415, 422, 421, 428, 427, 104, 103, 56, 55, 17, 0, 0, 0, 0, 0, 0, 0, 21, 20, 86, 85, 434, 433, 440, 439, 446, 445, 834, 833,
    418, 417, 424, 423, 430, 429, 106, 105, 58, 57, 0, 0, 0, 0, 0, 0, 0, 0, 23, 22, 88, 87, 436, 435, 442, 441, 448, 447, 835, 0,
    420, 419, 426, 425, 432, 431, 108, 107, 60, 59, 0, 0, 0, 0, 0, 0, 0, 0, 0, 24, 90, 89, 438, 437, 444, 443, 450, 449, 837, 836,
    482, 481, 476, 475, 470, 469, 49, 0, 31, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 54, 53, 464, 463, 458, 457, 452, 451, 838, 0,
    484, 483, 478, 477, 472, 471, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 466, 465, 460, 459, 454, 453, 840, 839,
    486, 485, 480, 479, 474, 473, 52, 51, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 43, 468, 467, 462, 461, 456, 455, 841, 0,
    488, 487, 494, 493, 500, 499, 98, 97, 62, 61, 0, 0, 0, 0, 0, 0, 0, 0, 0, 27, 92, 91, 506, 505, 512, 511, 518, 517, 843, 842,
    490, 489, 496, 495, 502, 501, 100, 99, 64, 63, 0, 0, 0, 0, 0, 0, 0, 0, 29, 28, 94, 93, 508, 507, 514, 513, 520, 519, 844, 0,
    492, 491, 498, 497, 504, 503, 102, 101, 66, 65, 18, 0, 0, 0, 0, 0, 0, 0, 19, 30, 96, 95, 510, 509, 516, 515, 522, 521, 846, 845,
    560, 559, 554, 553, 548, 547, 542, 541, 74, 73, 33, 0, 0, 0, 0, 0, 0, 11, 68, 67, 116, 115, 536, 535, 530, 529, 524, 523, 847, 0,
    562, 561, 556, 555, 550, 549, 544, 543, 76, 75, 0, 0, 8, 7, 36, 35, 12, 0, 70, 69, 118, 117, 538, 537, 532, 531, 526, 525, 849, 848,
    564, 563, 558, 557, 552, 551, 546, 545, 78, 77, 0, 34, 10, 9, 26, 25, 0, 0, 72, 71, 120, 119, 540, 539, 534, 533, 528, 527, 850, 0,
    566, 565, 572, 571, 578, 577, 584, 583, 590, 589, 596, 595, 602, 601, 608, 607, 614, 613, 620, 619, 626, 625, 632, 631, 638, 637, 644, 643, 852, 851,
    568, 567, 574, 573, 580, 579, 586, 585, 592, 591, 598, 597, 604, 603, 610, 609, 616, 615, 622, 621, 628, 627, 634, 633, 640, 639, 646, 645, 853, 0,
    570, 569, 576, 575, 582, 581, 588, 587, 594, 593, 600, 599, 606, 605, 612, 611, 618, 617, 624, 623, 630, 629, 636, 635, 642, 641, 648, 647, 855, 854,
    728, 727, 722, 721, 716, 715, 710, 709, 704, 703, 698, 697, 692, 691, 686, 685, 680, 679, 674, 673, 668, 667, 662, 661, 656, 655, 650, 649, 856, 0,
    730, 729, 724, 723, 718, 717, 712, 711, 706, 705, 700, 699, 694, 693, 688, 687, 682, 681, 676, 675, 670, 669, 664, 663, 658, 657, 652, 651, 858, 857,
    732, 731, 726, 725, 720, 719, 714, 713, 708, 707, 702, 701, 696, 695, 690, 689, 684, 683, 678, 677, 672, 671, 666, 665, 660, 659, 654, 653, 859, 0,
    734, 733, 740, 739, 746, 745, 752, 751, 758, 757, 764, 763, 770, 769, 776, 775, 782, 781, 788, 787, 794, 793, 800, 799, 806, 805, 812, 811, 861, 860,
    736, 735, 742, 741, 748, 747, 754, 753, 760, 759, 766, 765, 772, 771, 778, 777, 784, 783, 790, 789, 796, 795, 802, 801, 808, 807, 814, 813, 862, 0,
    738, 737, 744, 743, 750, 749, 756, 755, 762, 761, 768, 767, 774, 773, 780, 779, 786, 785, 792, 791, 798, 797, 804, 803, 810, 809, 816, 815, 864, 863
  );

  { from Appendix A - ASCII character to Code Set (e.g. 2 = Set B) }
  { set 0 refers to special characters that fit into more than one set (e.g. GS) }
  maxiCodeSet : array[0..255] of Integer = ( 
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0, 5, 0, 2, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 2,
    2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 4, 5, 5, 5, 5, 5, 5, 4, 5, 3, 4, 3, 5, 5, 4, 4, 3, 3, 3,
    4, 3, 5, 4, 4, 3, 3, 4, 3, 3, 3, 4, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
  );

  { from Appendix A - ASCII character to symbol value }
  maxiSymbolChar : array[0..255] of Integer = ( 
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
    20, 21, 22, 23, 24, 25, 26, 30, 28, 29, 30, 35, 32, 53, 34, 35, 36, 37, 38, 39,
    40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 37,
    38, 39, 40, 41, 52, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 42, 43, 44, 45, 46, 0, 1, 2, 3,
    4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
    24, 25, 26, 32, 54, 34, 35, 36, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 47, 48,
    49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 36,
    37, 37, 38, 39, 40, 41, 42, 43, 38, 44, 37, 39, 38, 45, 46, 40, 41, 39, 40, 41,
    42, 42, 47, 43, 44, 43, 44, 45, 45, 46, 47, 46, 0, 1, 2, 3, 4, 5, 6, 7,
    8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 32,
    33, 34, 35, 36, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 32, 33, 34, 35, 36
  );

type
  TMaxiCodeword = array[0..143] of Integer;
  
var
  maxi_codeword: TMaxiCodeword;

{ Handles error correction of primary message }  
procedure maxi_do_primary_check;
const
  datalen = 10;
  ecclen = 10;
var
  data: array[0..14] of byte;
  res: array[0..14] of byte;
  j: Integer;
begin
  rs_init_gf($43);
  rs_init_code(ecclen, 1);
  
  for j:= 0 to datalen-1 do
    data[j] := maxi_codeword[j];
    
  rs_encode(datalen, @data[0], @res[0]);
  
  for j := 0 to ecclen-1 do
    maxi_codeword[datalen + j] := res[ecclen - 1 - j];
    
  rs_free;
end;

{ Handles error correction of odd characters in secondary message }
procedure maxi_do_secondary_check_odd(ecclen: Integer);
var
  data: array[0..99] of byte;
  res: array[0..29] of byte;
  datalen: Integer;
  j: Integer;
 begin
   if ecclen = 20 then
     datalen := 84 
   else
     datalen := 68;

   rs_init_gf($43);
   rs_init_code(ecclen, 1);

   for j := 0 to datalen-1 do
     if odd(j) then
       data[(j-1) div 2] := maxi_codeword[j + 20];

   rs_encode(datalen div 2, @data[0], @res[0]);

   for j := 0 to ecclen-1 do
     maxi_codeword[datalen + 2*j + 21] := res[ecclen - 1 - j];
     
   rs_free;
end;

{ Handles error correction of even characters in secondary message }
procedure maxi_do_secondary_check_even(ecclen: Integer);
var
  data: array[0..99] of byte;
  res: array[0..29] of byte;
  j: Integer;
  datalen: Integer;
begin
  if ecclen = 20 then
    datalen := 84
  else
    datalen := 68;

  rs_init_gf($43);
  rs_init_code(ecclen, 1);
  
  for j := 0 to datalen do   // missing -1 is ok here.
    if not odd(j) then
      data[j div 2] := maxi_codeword[j + 20];
      
  rs_encode(datalen div 2, @data[0], @res[0]);
  
  for j := 0 to ecclen-1 do
    maxi_codeword[datalen + 2*j + 20] := res[ecclen - 1 - j];
    
  rs_free;
end;

{ Moves everything up so that a SHIFT or LATCH can be inserted. }
procedure maxi_bump(var ASet: TIntegerDynArray; var AChar: TIntegerDynArray; bump_pos: Integer);
var
  i: Integer;
begin
  for i := 143 downto bump_pos+1 do
  begin
    ASet[i] := ASet[i-1];
    AChar[i] := AChar[i-1];
  end;
end;

{ Format text according to Appendix A

  This code does not make use of [Lock in C], [Lock in D] and [Lock in E],
  and so is not always the most efficient at compressing data, but should
  suffice for most applications. }
function maxi_text_process(AMode: Integer; ASource: PByte; ALength: Integer): Integer;
var
  _set: TIntegerDynArray = nil;
  _char: TIntegerDynArray = nil;
  i, j, count: Integer;
  current_set: Integer;
  value: Integer;
  P: PByte;
  substring: string[10] = '';
begin
  if ALength > 138 then
  begin
    Result := ERROR_TOO_LONG;
    exit;
  end;
  
  SetLength(_set, 144);
  SetLength(_char, 144);
  
  for i := 0 to High(_set) do
  begin
    _set[i] := -1;
    _char[i] := 0;
  end;
  
  { Lookup characters in table from Appendix A - this givees value and code set
    for most characters. }
  P := ASource;
  for i := 0 to ALength-1 do
  begin
    _set[i] := maxiCodeset[ord(P^)];
    _char[i] := maxiSymbolChar[ord(P^)];
    inc(P);
  end;

  { If a character cannot be represented in more than one code set, pick which
    version to use }
  if _set[0] = 0 then
  begin
    if _char[0] = 13 then _char[0] := 0;
    _set[0] := 1;
  end;
  
  for i := 1 to ALength-1 do          // Beginning with 1 is intentional here.
  begin
    if _set[i] = 0 then
    begin
      // Special character
      case _char[i] of
        13: // carriage return
          if _set[i-1] = 5 then
          begin
            _char[i] := 13;
            _set[i] := 5;
          end else
          if (i <> ALength - 1) and (_set[i+1] = 5) then
          begin
            _char[i] := 13;
            _set[i] := 5;
          end else
          begin
            _char[i] := 0;
            _set[i] := 1;
          end;
      
        28:  // FS
          if _set[i-1] = 5 then
          begin
            _char[i] := 32;
            _set[i] := 5;
          end else
            _set[i] := _set[i-1];
            
        29:  // GS
          if _set[i-1] = 5 then
          begin
            _char[i] := 33;
            _set[i] := 5;
          end else
            _set[i] := _set[i-1];
            
        30:  // RS
          if _set[i-1] = 5 then
          begin
            _char[i] := 34;
            _set[i] := 5;
          end else
            _set[i] := _set[i-1];
            
        32:  // Space
          case _set[i-1] of
            1: begin
                 _char[i] := 32;
                 _set[i] := 1;
               end;
            2: begin
                 _char[i] := 47;
                 _set[i] := 2;
               end;
             else
               if _set[i-1] >= 3 then
               begin
                 if (i <> ALength - 1) then
                   case _set[i+1] of
                     1: begin
                          _char[i] := 32;
                          _set[i] := 1;
                        end;
                     2: begin
                          _char[i] := 47;
                          _set[i] := 2;
                        end;
                     else
                        if _set[i+1] >= 3 then
                        begin
                          _char[i] := 59;
                          _set[i] := _set[i-1];
                        end;
                   end
                 else
                 begin
                   _char[i] := 59;
                   _set[i] := _set[i-1];
                 end;
               end;
          end;  // case _set[i-1]

        44:  // Comma
          if _set[i-1] = 2 then
          begin
            _char[i] := 48;
            _set[i] := 2;
          end else
          if (i <> Alength-1) and (_set[i+1] = 2) then
          begin
            _char[i] := 48;
            _set[i] := 2;
          end else
            _set[i] := 1;
            
        46:  // Full stop
          if _set[i-1] = 2 then
          begin
            _char[i] := 49;
            _set[i] := 2;
          end else
          if (i <> Alength-1) and (_set[i+1] = 2) then
          begin
            _char[i] := 49;
            _set[i] := 2;
          end else
            _set[i] := 1;
            
        47:  // Slash
          if _set[i-1] = 2 then
          begin
            _char[i] := 50;
            _set[i] := 2;
          end else
          if (i <> ALength-1) and (_set[i+1] = 2) then
          begin
            _char[i] := 50;
            _set[i] := 2;
          end else
            _set[i] := 1;
            
        58:  // Colon
          if _set[i-1] = 2 then
          begin
            _char[i] := 51;
            _set[i] := 2;
          end else
          if (i <> ALength-1) and (_set[i+1] = 2) then
          begin
            _char[i] := 51;
            _set[i] := 2;
          end else
            _set[i] := 1;
      end;  // case char[i]
    end;  // if _set[i] = 0
  end;  // for i 
      
  // Add the padding
  for i := ALength to High(_set) do
  begin
    if _set[ALength-1] = 2 then
      _set[i] := 2
    else
      _set[i] := 1;
    _char[i] := 33;
  end;
  
  { Find candidates for number compression }
  count := 0;
  if (AMode = 2) or (AMode = 3) then
    j := 0
  else
    j := 9;
  for i := j to High(_set) do
  begin
    if (_set[i] = 1) and (_char[i] >= 48) and (_char[i] <= 57) then
      // Character is a number
      inc(count)
    else
      count := 0;
    // Nine digits in a row can be compressed
    if count = 9 then
    begin
      _set[i] := 6;
      _set[i-1] := 6;
      _set[i-2] := 6;
      _set[i-3] := 6;
      _set[i-4] := 6;
      _set[i-5] := 6;
      _set[i-6] := 6;
      _set[i-7] := 6;
      _set[i-8] := 6;
      count := 0;
    end;
  end;
  
  { Add SHIFT and LATCH characters }
  current_set := 1;
  i := 0;
  while i < Length(_set) do
  begin
    if _set[i] <> current_set then
    begin
      case _set[i] of
        1: if _set[i+1] = 1 then
           begin
             if _set[i+2] = 1 then
             begin
               if _set[i+3] = 1 then
               begin
                 // Latch A
                 maxi_bump(_set, _char, i);
                 _char[i] := 63;
                 current_set := 1;
                 inc(ALength);
               end else
               begin
                 // 3 Shift A
                 maxi_bump(_set, _char, i);
                 _char[i] := 57;
                 inc(ALength);
                 inc(i, 2);
               end;
             end else
             begin
               // 2 Shift A
               maxi_bump(_set, _char, i);
               _char[i] := 56;
               inc(ALength);
               inc(i);
             end;
           end else
           begin
             // Shift A
             maxi_bump(_set, _char, i);
             _char[i] := 59;
             inc(ALength);
           end;
           
        2: begin
             if _set[i+1] = 2 then
             begin
               // Latch B
               maxi_bump(_set, _char, i);
               _char[i] := 63;
               current_set := 2;
               inc(ALength);
             end else
             begin
               // Shift B
               maxi_bump(_set, _char, i);
               _char[i] := 59;
               inc(ALength);
             end;
           end;
           
        3: begin
             // Shift C
             maxi_bump(_set, _char, i);
             _char[i] := 60;
             inc(ALength);
           end;
          
        4: begin
             // Shift D
             maxi_bump(_set, _char, i);
             _char[i] := 61;
             inc(ALength);
           end;
          
        5: begin
             // Shift E
             maxi_bump(_set, _char, i);
             _char[i] := 62;
             inc(ALength);
           end;
          
        6: ; // Number compressed, do nothing
      end;
      inc(i);
    end;  //if _set[i] <> current_set
    inc(i);
  end;  // while
  
  { Number compression has not been forgotten. It is handled below }
  i := 0;
  while i < Length(_set) do
  begin
    if _set[i] = 6 then
    begin
      // Number compression
      SetLength(substring, 9);
      for j := 0 to 8 do
        substring[j+1] := char(_char[i+j]);
      value := StrToInt(substring);
      
      _char[i] := 31;  // NS
      _char[i+1] := (value and $3f000000) shr 24;
      _char[i+2] := (value and $fc0000) shr 18;
      _char[i+3] := (value and $3f000) shr 12;
      _char[i+4] := (value and $fc0) shr 6;
      _char[i+5] := (value and $3f);
      inc(i, 6);
      for j := i to 139 do
      begin
        _set[j] := _set[j+3];
        _char[j] := _char[i+3];
      end;
      dec(ALength, 3);
    end else
      inc(i);
  end;  // while
  
  case AMode of
    2, 3: 
      begin
        if (ALength > 84) then
        begin
          Result := ERROR_TOO_LONG;
          exit;
        end;
        // Copy the encoded text into the codeword array
        for i := 0 to 83 do  // secondary only
          maxi_codeword[i+20] := _char[i];
      end;
      
    4, 6:
      begin
        if (ALength > 93) then
        begin
          Result := ERROR_TOO_LONG;
          exit;
        end;
        for i := 0 to 8 do  // primary
          maxi_codeword[i+1] := _char[i];
        for i := 0 to 83 do  // secondary
          maxi_codeword[i+20] := _char[i+9]
      end;
      
    5: 
      begin
        if ALength > 77 then
        begin
          Result := ERROR_TOO_LONG;
          exit;
        end;
        for i := 0 to 8 do  // primary
          maxi_codeword[i+1] := _char[i];
        for i := 0 to 67 do  // secondary
          maxi_codeword[i+20] := _char[i+9];
      end;
  end;
  
  Result := 0;
end;

{ Format structured primary for Mode 2.
  Returns FALSE if APostCode is not a numeric string. }
function maxi_do_primary_2(APostCode: String; ACountry, AService: Integer): Boolean;
var
  postcode_number: Integer;
  postcode_length: Integer;
begin
  postcode_length := Length(APostcode);
  if (postcode_length = 0) or not TryStrToInt(APostCode, postcode_number) then
  begin
    Result := false;
    exit;
  end;
      
  maxi_codeword[0] := ((postcode_number and $03) shl 4) or 2;
  maxi_codeword[1] := ((postcode_number and $fc) shr 2);
  maxi_codeword[2] := ((postcode_number and $3f00) shr 8);
  maxi_codeword[3] := ((postcode_number and $fc000) shr 14);
  maxi_codeword[4] := ((postcode_number and $3f00000) shr 20);
  maxi_codeword[5] := ((postcode_number and $3c000000) shr 26) or ((postcode_length and $3) shl 4);
  maxi_codeword[6] := ((postcode_length and $3c) shr 2) or ((ACountry and $3AC) shl 4);
  maxi_codeword[7] := (ACountry and $fc) shr 2;
  maxi_codeword[8] := ((ACountry and $300) shr 8) or ((AService and $f) shl 2);
  maxi_codeword[9] := ((AService and $3f0) shr 4);  
  
  Result := true;
end;
 
{ Format structured primary for Mode 3 }
procedure maxi_do_primary_3(APostCode: String; ACountry, AService: Integer);
var
  i: Integer;
  ch: Char;
begin
  for i := 1 to Length(APostCode) do
  begin
    ch := Upcase(APostcode[i]);
    // (Capital) letters shifted to Code Set A values
    if (ch in ['A'..'Z']) then
      APostcode[i] := char(ord(ch) - 64);
    
    // Not a valid PostCode character?
    if (ch in [#27, #31, #33]) or (ch >= #59) then
      APostcode[i] := ' ';
    
    // Input characters below 27 (NUL..SUB) in PostCode are interpreted
    // as a capital letter in Code Set A (e.g. LF becomes 'J');
  end;
    
  maxi_codeword[0] := ((Ord(APostCode[6]) and $03) shl 4) or 3;
  maxi_codeword[1] := ((Ord(APostCode[5]) and $03) shl 4) or ((Ord(APostCode[6]) and $3c) shr 2);
  maxi_codeword[2] := ((Ord(APostCode[4]) and $03) shl 4) or ((Ord(APostCode[5]) and $3c) shr 2);
  maxi_codeword[3] := ((Ord(APostCode[3]) and $03) shl 4) or ((Ord(APostCode[4]) and $3c) shr 2);
  maxi_codeword[4] := ((Ord(APostCode[2]) and $03) shl 4) or ((Ord(APostCode[3]) and $3c) shr 2);
  maxi_codeword[5] := ((Ord(APostCode[1]) and $03) shl 4) or ((Ord(APostCode[2]) and $3c) shr 2);
  maxi_codeword[6] := ((Ord(APostCode[1]) and $3c) shr 2) or ((ACountry and $3) shl 4);
  maxi_codeword[7] := (ACountry and $fc) shr 2;
  maxi_codeword[8] := (((ACountry and $300) shr 8)) or ((AService and $f) shl 2);
  maxi_codeword[9] := ((AService and $3f0) shr 4);
end;

function maxicode(ASymbol: PZintSymbol; ASource: String): Integer;
var
  i, j, mode, countrycode, service: Integer;
  lp: Integer = 0;
  block: Integer = 0;
  bit: Integer = 0;
  bit_pattern: array[0..6] of integer;
  eclen: Integer;
  postcode: String = '';
  countrystr: string[3];
  servicestr: string[3];
  local_source: String;
begin
  local_source := ASource;
  maxi_codeword := Default(TMaxiCodeword);
  
  mode := ASymbol^.Option_1;
  { mode is not specified }
  if (mode <= 0) then
  begin
    lp := StrLen(ASymbol^.Primary);
    if lp = 0 then
      mode := 4
    else
    begin
      mode := 2;
      j := 10;
      if lp < j then j := lp;
      for i := 0 to j-1 do
        if (ASymbol^.primary[i] < #48) or (ASymbol^.primary[i] > #57) then
        begin
          mode := 3;
          break;
        end;
    end;
  end;
  
  { Only modes 2 to 6 supported }
  if (mode < 2) or (mode > 6) then
  begin
    ASymbol^.SetErrorText('Invalid Maxicode Mode');
    Result := ERROR_INVALID_OPTION;
    exit;
  end;
  
  { Modes 2 and 3 need data in ASymbol^.Primary }
  if (mode = 2) or (mode = 3) then
  begin
    if lp = 0 then   // Mode set manually means: lp doesn't get set
      lp := Length(ASymbol^.GetPrimary);
    if lp <> 15 then
    begin
      ASymbol^.SetErrorText('Primary String Length Error (15 characters needed).');
      Result := ERROR_INVALID_DATA;
      exit;
    end;
    
    { Check that country code and service are numeric }
    for i := 9 to 14 do
      if not (ASymbol^.Primary[i] in ['0'..'9']) then
      begin
        ASymbol^.SetErrorText('Invalid Primary String');
        Result := ERROR_INVALID_DATA;
        exit;
      end;
    
    postcode := Copy(ASymbol^.GetPrimary, 1, 9);

    if mode = 2 then
    begin
      for i := 1 to Length(postcode) do
        if postcode[i] = ' ' then
        begin
          SetLength(postcode, i-1);
          break;
        end;
    end else
      SetLength(postcode, 6);

    countrystr := Copy(ASymbol^.GetPrimary, 10, 3);
    if not TryStrToInt(countrystr, countrycode) or (countrycode < 0) then
    begin
      ASymbol^.SetErrorText('Invalid country code.');
      Result := ERROR_INVALID_DATA;
      exit;
    end;

    servicestr := Copy(ASymbol^.GetPrimary, 13, 3);
    if not TryStrToInt(servicestr, service) then
    begin
      ASymbol^.SetErrorText('Invalid service code.');
      Result := ERROR_INVALID_DATA;
      exit;
    end;

    case mode of
      2: if not maxi_do_primary_2(postcode, countrycode, service) then
         begin
           ASymbol^.SetErrorText('Invalid post code.');
           Result := ERROR_INVALID_DATA;
           exit;
         end;  
      3: maxi_do_primary_3(postcode, countrycode, service);
      else ;
    end;
  end else
    maxi_codeword[0] := mode;
  
  i := maxi_text_process(mode, @local_source[1], Length(local_source));
  if (i = ERROR_TOO_LONG) then
  begin
    ASymbol^.SetErrorText('Input data too long.');
    Result := i;
    exit;
  end;
  
  // All the data is sorted - now do error corretion
  maxi_do_primary_check();  // always EEC
  
  if mode = 5 then
    eclen := 56    // 68 data codewords, 56 error corrections
  else
    eclen := 40;   // 84 data codewords, 40 error corretions
  
  maxi_do_secondary_check_even(eclen div 2);  // do error correction of even
  maxi_do_secondary_check_odd(eclen div 2);   // do error correction of odd
  
  // Copy data into symbol grid
  for i := 0 to 32 do
    for j := 0 to 29 do
    begin
      DivMod(MaxiGrid[i*30 + j] + 5, 6, block, bit);
      if block <> 0 then
      begin
        bit_pattern[0] := (maxi_codeword[block-1] and $20) shr 5;
        bit_pattern[1] := (maxi_codeword[block-1] and $10) shr 4;
        bit_pattern[2] := (maxi_codeword[block-1] and $08) shr 3;
        bit_pattern[3] := (maxi_codeword[block-1] and $04) shr 2;
        bit_pattern[4] := (maxi_codeword[block-1] and $02) shr 1;
        bit_pattern[5] := (maxi_codeword[block-1] and $01);
        if bit_pattern[bit] <> 0 then
          set_module(ASymbol, i, j);
      end;
    end;
  
  // Add orientation markings
  set_module(ASymbol, 0, 28);  // Top right filler
  set_module(ASymbol, 0, 29);
  set_module(ASymbol, 9, 10);  // Top left marker
  set_module(ASymbol, 9, 11);
  set_module(ASymbol, 10, 11);
  set_module(ASymbol, 15, 7);  // Left hand marker
  set_module(ASymbol, 16, 8);
  set_module(ASymbol, 16, 20);  // Right hand marker
  set_module(ASymbol, 17, 20);
  set_module(ASymbol, 22, 10);  // Bottom left marker
  set_module(ASymbol, 23, 10);
  set_module(ASymbol, 22, 17);  // Bottom right marker
  set_module(ASymbol, 23, 17);
  
  ASymbol^.Width := 30;
  ASymbol^.Rows := 33;
  
  Result := 0;
end;

end.
