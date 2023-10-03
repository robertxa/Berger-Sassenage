Scale:=8.00;
MagDecl:=0.00;
GridConv:=0.00;
BaseScale:=4.00;
color HelpSymbolColor;
HelpSymbolColor := (0.8, 0.8, 0.8);
background:=(1.00000,1.00000,1.00000);
verbatimtex \input th_enc.tex etex;
%% therion source code
%%
%% therion.mp
%%
%% This file defines low-level MetaPost macros and variables required
%% for generation of map symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: therion.mp,v $
%% $Revision: 1.3 $
%%
%% Copyright (C) 2000-2003 Martin Budaj
%%
%% Some macros are adapted from MPATTERN package of P. Bolek
%%
%% Some macros are used from MetaFun package of H. Hagen
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

%    This file defines low level macros used for map signatures in Therion.
%    Before loading this file set `Scale' variable to numeric value
%    representing denominator of the scale ratio. Internal variable 
%    `prologues' is set to 1 by this file. This module loads also 
%    symbol libraries.


tracingstats:=1;
prologues:=0;

if known Background: background:=Background fi;
%TrueScale:=Scale;

% @VARIABLE
% symbol_scale --
%
% <I>internal numeric</I>; in map symbol definitions used for scaling
% in <A HREF="#T">T</A> transformation; recommended
% values are 1 or 2.

%newinternal symbol_scale;
%symbol_scale := 1;

% @VARIABLE
% fill_only --
%
% <I>boolean</I>, used in <A HREF="#thdraw">thdraw</A> and
% <A HREF="#thpattfill">thpattfill</A> commands. When set to false, it has 
% no effect, when it is true, it supresses all drawing 
% commands with exception of <I>thpermanentfill</I>, so that only filled 
% areas are drawn

boolean fill_only, horiz_labels, transparency;
fill_only := false;
horiz_labels:=true;
transparency:=false;

string ATTR__id, ATTR__survey, ATTR__scrap, NorthDir;
boolean ATTR__scrap_centerline;
picture ATTR__text;
numeric ATTR__height;
boolean ATTR__elevation;
ATTR__scrap_centerline := false;
ATTR__height:=0;
ATTR__elevation:=false;

boolean ATTR__shotflag_splay;
ATTR__shotflag_splay:=false;
boolean ATTR__shotflag_duplicate;
ATTR__shotflag_duplicate:=false;
boolean ATTR__shotflag_approx;
ATTR__shotflag_approx:=false;
boolean ATTR__stationflag_splay;
ATTR__stationflag_splay:=false;


color label_fill_color, label_fill_color_tmp;
label_fill_color := (1.0, 1.0, 1.0);
def push_label_fill_color(expr r,g,b) =
  label_fill_color_tmp := label_fill_color;
  label_fill_color := (r,g,b);
enddef;
def pop_label_fill_color =
  label_fill_color := label_fill_color_tmp;
enddef;
def process_filledlabel(expr cent, rot) =
  begingroup;
    interim bboxmargin:=2.0bp;
    q:=((bbox lab) smoothed 2) rotatedaround (cent, rot);
    fill q withcolor label_fill_color;
    draw lab rotatedaround (cent, rot);
    write_circ_bbox(q);  % without corners smoothing it was enough to use
                         % write_bbox(q);
  endgroup;
enddef;




numeric area_border_errors;
area_border_errors = 0;

% @VARIABLE
% last_write --
%
% <I>numeric</I>; charcode of last figure which contained 
% <A HREF="#write_bbox">write_bbox</A> macro; this value is used by
% <A HREF="#close_file">close_file</A> macro. Initially set to -1.

numeric last_write;
last_write = -1;

% @VARIABLE
% strut_string --
%
% <I>string</I> containing combination of the "highest" and "lowest" character
% in used font; it's used by <A HREF="">free_text</A> macro.

%string strut_string;
%strut_string = "(È";

% @VARIABLE
% file_name --
%
% <I>string</I>, name of file, where <I>write_bbox</I> macro writes
% text clipping path

% @VARIABLE
% s ch --
%
% <I>string</I>, temporary string/char variables

string s, ch, file_name, bg_name, clip_name, lang, diff_pos, diff_neg,
     current_scrap, current_src;

% @VARIABLE
% u v w --
%
% <I>internal numeric variables</I> used as basic length units for drawing;
% they are set by <A HREF="#initialize">initialize</A> macro.
% <UL> <LI><I>u</I> -- normal unit decreasing with increasing scale
%      <LI><I>v</I> -- like <I>u</I>, but can increase drammaticaly
%            when some limit is encountered (to get effects like logarithmic
%            scale)
%      <LI><I>w</I> -- nearly constant at all scales
% </UL>

% @VARIABLE
% legend_scale --
%
% <I>numeric</I>, length of the longer side of signatures' legend box

newinternal legend_scale, u,v,w;

% @VARIABLE
% lab Lab --
%
% <I>picture</I>, in which are saved typeset labels

picture lab, Lab;

% @VARIABLE
% T --
%
% <I>transformation</I>, defines transformation function for transforming 
% every argument of <A HREF="#thdraw>thdraw</A> and <A HREF="#thfill>thfill</A>
% macros

transform T;

% @VARIABLE
% p,q --
%
% <I>path</I>, for saving temporary paths

path p,q;

% @MACRO
% initialize --
%
% initializes basic length units <A HREF="#u">(u,v,w)</A> and pens used 
% in map symbols according to scale. Five circular pens are defined:
% <UL><LI>PenA -- thick; for outlines
%    <LI>PenB, PenC -- thinner; for pits, symbols etc.
%    <LI>PenD -- thinnest; for fine details
%    <LI>PenX -- extra thick; not recommended for use
% </UL>

def fonts_setup (expr t,s,m,l,h) =
  write "\def\updown#1#2{\vbox{" &
        "\offinterlineskip" &
        "\setbox100=\hbox{#1}" &
        "\setbox101=\hbox{#2}" &
        "\ifnum\wd100>\wd101\hsize=\wd100\else\hsize=\wd101\fi" &
        "\centerline{\box100}\vskip4pt" &
        "\centerline{\box101}}}" &
        "\def\thlabel{\thnormalsize}" &
        "\def\thremark{\thsmallsize\si}" &
        "\def\thcomment{\thsmallsize}" &
        "\def\thentrance{\thsmallsize}" &
        "\def\thaltitude{\thsmallsize}" &
        "\def\thstationname{\thsmallsize}" &
        "\def\thdate{\thsmallsize}" &
        "\def\thheight{\thsmallsize}" &
        "\def\thheightpos{+\ignorespaces}" &
        "\def\thheightneg{-\ignorespaces}" &
        "\def\thframed{\thsmallsize}" &
        "\def\thwallaltitude{\thtinysize}"
  to "mptexpre.tex";
  write "\def\thtinysize{\size[" & decimal max(optical_zoom*t,0) & "]}" & 
        "\def\thsmallsize{\size[" & decimal max(optical_zoom*s,0) & "]}" & 
        "\def\thnormalsize{\size[" & decimal max(optical_zoom*m,0) & "]}" & 
        "\def\thlargesize{\size[" & decimal max(optical_zoom*l,0) & "]}" & 
        "\def\thhugesize{\size[" & decimal max(optical_zoom*h,0) & "]}" 
  to "mptexpre.tex";
  write EOF to "mptexpre.tex";
enddef;

def initialize (expr sc) =

  if unknown BaseScale: BaseScale = sc; fi;
  optical_zoom := BaseScale/sc;

    if BaseScale <= 1:                   % 1:100
        u:=14bp; v:=14bp; w:=12bp;
        fonts_setup(8,10,12,16,24);
    elseif BaseScale <= 2:               % 1:200
        u:=12bp; v:=12bp; w:=12bp;
        fonts_setup(7,8,10,14,20);
    elseif BaseScale <= 5:               % 1:500
        u:=10bp; v:=10bp; w:=12bp;
        fonts_setup(6,7,8,10,14);
    else:
        u:=7bp; v:=14bp; w:=10bp;
        fonts_setup(5,6,7,8,10);
    fi;
    
    u := optical_zoom * u;
    v := optical_zoom * v;
    w := optical_zoom * w;

    defaultscale := 0.8 * optical_zoom;

    def PenA = pencircle scaled (u/10) enddef;
    def PenB = pencircle scaled (0.7*u/10) enddef;
    def PenC = pencircle scaled (0.5*u/10) enddef;
    def PenD = pencircle scaled (0.35*u/10) enddef;
    def PenX = pencircle scaled (1.2*u/10) enddef;
    
    legend_scale := 3.14*u;
enddef;

% macro is expanded, we have to know all dimensions and pens before reading
% mpattern macros

initialize(Scale);

vardef thTEX primary s =
  write "verbatimtex \input th_enc.tex etex" to "mptextmp.mp";
  write "btex \mainfont "&s&" etex" to "mptextmp.mp";
  write EOF to "mptextmp.mp";
  scantokens "input mptextmp"
enddef;

% @MACRO
% inscale --
%
% zooms objects to scale specified in legend_scale variable (used in legend
% typesetting)

def inscale = 
    xscaled legend_scale yscaled (0.618*legend_scale)
enddef;

% @MACRO
% draw_legend_box --
%
% draws a legend bounding box and resets drawoptions() options 

def draw_legend_box =
    clip currentpicture to unitsquare inscale;
    drawoptions();
    pickup PenB;
    draw unitsquare inscale;
enddef;

def clean_legend_box =
  unfill unitsquare inscale;
enddef;

def legend_point (expr name) =
%  if substring (2,9) of name = "station":
%    scantokens(name)((0.5,0.5) inscale);
%  else:
    scantokens(name)((0.5,0.5) inscale,0,1,(0,0));
%  fi;
  draw_legend_box;
enddef;

def legend_line (expr name) =
  scantokens(name)((((-0.3,.5)..(.3,.7)..(.5,.3)..{dir 80}(1.3,.9)) inscale) 
                randomized 3mm);
  draw_legend_box;
enddef;

% legend_label
% legend_area
% legend_random

% @MACRO
% roundone --
%
% rounds <I>numeric value</I> to one decimal point

vardef roundone(expr n) =
%    round(10*n)/10
  n
enddef;

% @MACRO
% process_label --
%
% draws a label saved in <I>lab</I> picture variable and calls 
% <A HREF="#write_bbox">write_bbox</A> macro.


def process_label (expr cent, rot) =
  begingroup;
    interim bboxmargin:=0.8bp;
    q:=((bbox lab) smoothed 2) rotatedaround (cent, rot);
    draw lab rotatedaround (cent, rot);
    write_circ_bbox(q);  % without corners smoothing it was enough to use
                         % write_bbox(q);
  endgroup;
enddef;

% @MACRO
% process_uplabel --
%
% draws a label into semicircular box and writes clipping path to a file

def process_uplabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    q:=bbox lab;
  endgroup;
    alef:=.8-.02*(xpart lrcorner q - xpart llcorner q);
%    show alef;
    q:=alef[llcorner q,ulcorner q]{up} .. {down}alef[lrcorner q, urcorner q] --
        lrcorner q -- llcorner q -- cycle;
    draw lab;
    draw q;
    q:=reverse q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_downlabel --
%
% draws a label into down oriented semicircular box and writes
% clipping path to a file

def process_downlabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    q:=bbox lab;
  endgroup;
    alef:=1-(.8-.02*(xpart lrcorner q - xpart llcorner q));
    q:=alef[llcorner q,ulcorner q]{down} .. 
        {up}alef[lrcorner q, urcorner q] --
        urcorner q -- ulcorner q -- cycle;
    draw lab;
    draw q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_updownlabel --
%
% draws a label splitted into down and up oriented semicircular boxes and 
% writes clipping path to a file

def process_updownlabel =
  begingroup;
    interim bboxmargin := 0.8 bp;
    p:=bbox lab;
  endgroup;
    leftside:=xpart llcorner p;
    rightside:=xpart lrcorner p;
    draw (xpart llcorner p,.5[ypart llcorner p,ypart ulcorner p]) -- 
         (xpart lrcorner p,.5[ypart llcorner p,ypart ulcorner p]);
    alef:=1.05-.02*(xpart lrcorner p - xpart llcorner p);
%    alef:=.8-.02*(rightside-leftside);
    p:=alef[(leftside, ypart llcorner p),(leftside, ypart ulcorner p)]{up} .. 
       {down}alef[(rightside, ypart lrcorner p), (rightside, ypart urcorner p)]
        -- alef[(rightside, ypart urcorner p), (rightside, ypart lrcorner p)]{down}
        .. {up}alef[(leftside, ypart ulcorner p),(leftside, ypart llcorner p)]
        -- cycle;
%    p:=alef[llcorner p,ulcorner p]{up} .. {down}alef[lrcorner p, urcorner p] --
%        aleff[llcorner p,ulcorner p]{down} .. 
%        {up}aleff[lrcorner p, urcorner p] -- cycle;
    draw lab;
    draw p;
    p:=reverse p;
    write_circ_bbox(p);
enddef;

def process_updownlabel_OLD =
    p:=bbox lab;
    q:=bbox Lab;
    leftside:=min(xpart llcorner p, xpart ulcorner q);
    rightside:=max(xpart lrcorner p, xpart urcorner q);
    draw .5[(leftside, ypart llcorner p),(leftside, ypart ulcorner q)] -- 
         .5[(rightside,ypart lrcorner p),(rightside,ypart urcorner q)];
    alef:=.8-.02*(rightside-leftside);
    q:=alef[(leftside, ypart llcorner p),(leftside, ypart ulcorner p)]{up} .. 
       {down}alef[(rightside, ypart lrcorner p), (rightside, ypart urcorner p)]
        -- alef[(rightside, ypart urcorner q), (rightside, ypart lrcorner q)]{down}
        .. {up}alef[(leftside, ypart ulcorner q),(leftside, ypart llcorner q)]
        -- cycle;
    draw lab;
    draw Lab;
    draw q;
    q:=reverse q;
    write_circ_bbox(q);
enddef;

% @MACRO
% process_boxedlabel --
%
% draws a label into circular box and writes
% clipping path to a file

def process_boxedlabel =
    q:=bbox lab;
    draw lab;
    draw q;
    write_bbox(q);
enddef;

% @MACRO
% process_circledlabel --
%
% draws a label into circular box and writes
% clipping path to a file

def process_circledlabel =
  begingroup;
    interim bboxmargin := 0.4 bp;
    q:=bbox lab;
  endgroup;
    q:=point 0 of q .. point 1 of q .. point 2 of q .. point 3 of q .. cycle;
    draw lab;
    draw q;
    write_circ_bbox(q);
enddef;


% @MACRO
% write_bbox --
%
% Arguments:
%   <I>path</I> variable -- rectangular bounding box of a label;
%   assumptions: path is cyclic, counterclockwise oriented, with four points,
%   composed from linear segments;
%   see general <A HREF="#write_circ_bbox">write_circ_bbox</A> macro
% Results:
%   one file per figure which uses labels with a clipping path in pseudo-pdf 
%   format

def write_bbox (expr q) =
    file_name := jobname & "." & decimal(charcode) & "bbox";
    for i:=4 downto 0:
        s  :=  decimal(roundone(xpart point i of q)) & " " 
             & decimal(roundone(ypart point i of q)) 
             & if i=4: " m " else: " l" fi;
        write s to file_name;
    endfor;
    last_write := charcode;
enddef;

% @MACRO
% write_circ_bbox --
%
% Arguments:
%   <I>path</I> variable, only assumption is that <I>path</I> is cyclic
%   and counterclockwise oriented.
% Results:
%   one file per figure which uses labels with a clipping path in pseudo-pdf 
%   format

def write_circ_bbox expr q =
    file_name := jobname & "." & decimal(charcode) & "bbox";
    tmp:=length q;
    s :=  decimal(roundone(xpart point tmp of q)) & " " 
             & decimal(roundone(ypart point tmp of q)) & " m";
    write s to file_name;
    for i:=tmp downto 1:
        s :=  decimal(roundone(xpart precontrol i of q)) & " " 
             & decimal(roundone(ypart precontrol i of q)) & " "
             & decimal(roundone(xpart postcontrol i-1 of q)) & " " 
             & decimal(roundone(ypart postcontrol i-1 of q)) & " "
             & decimal(roundone(xpart point i-1 of q)) & " " 
             & decimal(roundone(ypart point i-1 of q)) & " c";
        write s to file_name;
    endfor;
    last_write := charcode;
enddef;

% @MACRO
% close_file --
%
% closes file with a clipping path; it's invoked by <I>endchar</I> macro

def close_file =
    if last_write=charcode:
        write EOF to jobname & "." & decimal(charcode) & "bbox";
    fi;
enddef;

% endchar should run close_file macro

extra_endfig := "close_file;";

% @MACRO
% thdraw --
%
% like plain MetaPost's <I>draw</I>, but draws a <I>path</I> transformed
% (rotated, scaled, shifted) to scrap's coordinates according T variable.
% (If <I>fill_only=false</I>)

def thdrawoptions(text t) =
  def _thop_ = t enddef
enddef;
thdrawoptions();

def thdraw expr p = 
  if not fill_only:
    addto currentpicture 
    if picture p: 
      also (p transformed T)
    else:
      doublepath (p transformed T) withpen currentpen 
    fi  
    _thop_  _op_
  else:
    addto currentpicture also nullpicture
  fi
enddef;

% @MACRO
% thfill --
%
% fills a <I>path</I> transformed
% (rotated, scaled, shifted) to scrap's coordinates according T variable.
% Filled areas are clipped (like most 
% other lines and points) with a clipping path around text labels.


def thfill expr c = 
    addto currentpicture contour (c transformed T) _thop_ _op_ 
enddef;

def thfilldraw expr c =
  if not fill_only:
    addto currentpicture contour (c transformed T) withpen currentpen _thop_ _op_ 
  else:
    addto currentpicture contour (c transformed T) _thop_ _op_ 
  fi
enddef;

def thunfill expr c = 
    thfill c withcolor background 
enddef;

def thundraw expr p = 
    thdraw p withcolor background 
enddef;

def thunfilldraw expr c = 
    thfilldraw c withcolor background 
enddef;

def thclean expr c =
  if transparency:
    thfill c withtransparentcolor tr_bg
  else:
    thunfill c
  fi;
enddef;

def thPatternFill (expr Path, Pattern) =
  T:=identity;
  thclean Path;
  thfill Path withpattern Pattern;
enddef;

%def thLegendPatternFill (expr Path, Pattern) =
%  T:=identity;
%  thfill Path withpattern Pattern;
%enddef;

% for drawarrow:

def _finarr text t =
  thdraw _apth t;
  thfilldraw arrowhead _apth  t
enddef;

% @MACRO
% thpermanentfill --
%
% Fills specified area with a solid color; this area is not affected by 
% text clipping path

%def thpermanentfill expr c = 
%    addto currentpicture contour (c transformed T) _thop_ _op_
%enddef;

let thpermanentfill = thfill;


primarydef p aligned al=
  p shifted (xpart al * xpart U, ypart al * ypart U)
enddef;

% macros for drawing scraps in upper and lower levels; filled lower scraps 
% require special treatment (MetaPost doesn't support non-continuous paths).
% We can't use one file for both, while PDF XObject has to be explicitely 
% filled or stroked. Second macro writes also pseudo-pdf code of a clipping 
% path for given scrap

boolean drawnext;
drawnext:=true;

def draw_upscrap (expr isout)(text t) =
  path q;
  for i=t:
    if (numeric i):
      if (i=1): drawnext:=true; else: drawnext:=false; fi;
    else:
      if drawnext: draw i withpen PenD; fi;
      if not known q: q:=i; else: q:=q -- i; fi;
    fi;
  endfor;
  if not cycle q: q:=q -- cycle; fi;
  if turningnumber q = 0: 
      thwarning("scrap outline intersects itself"); 
  fi;
  if isout=1:
    if turningnumber q > 0: q := reverse q; fi;
  else:
    if turningnumber q < 0: q := reverse q; fi;
  fi;
  addto bgfill contour q;
enddef;

% following macro writes noncontinuous PostScript path directly to EPS file
% (filled background and clipping path)

picture bgfill;
bgfill:=nullpicture;

def draw_downscrap =
  bg_name := jobname & "." & decimal(charcode) & "bg";
  clip_name := jobname & "." & decimal(charcode) & "clip";
  write "%!PS" to bg_name;
  write "%%BoundingBox: " & 
     decimal floor xpart llcorner bgfill & " " &
     decimal floor ypart llcorner bgfill & " " &
     decimal ceiling xpart urcorner bgfill & " " &
     decimal ceiling ypart urcorner bgfill 
     to bg_name;
  write "%%Page: 1 1" to bg_name;
  write "newpath" to bg_name;
  for qq within bgfill:
    q := pathpart qq;
    tmp:=length q;
    s := decimal(roundone(xpart point tmp of q)) & " " 
             & decimal(roundone(ypart point tmp of q)) & " m";
    write s & "oveto" to bg_name;
    write s to clip_name;
    for i:=tmp downto 1:
        s :=  decimal(roundone(xpart precontrol i of q)) & " " 
             & decimal(roundone(ypart precontrol i of q)) & " "
             & decimal(roundone(xpart postcontrol i-1 of q)) & " " 
             & decimal(roundone(ypart postcontrol i-1 of q)) & " "
             & decimal(roundone(xpart point i-1 of q)) & " " 
             & decimal(roundone(ypart point i-1 of q)) & " c";
        write s & "urveto" to bg_name;
        write s to clip_name;
    endfor;
  endfor;
  write "closepath fill" to bg_name;
  write "showpage" to bg_name;
  write "%%EOF" to bg_name;
  write EOF to bg_name;
  write EOF to clip_name;
  bgfill:=nullpicture;
enddef;



vardef buildcycle(text ll) =
  save ta_, tb_, k_, i_, pp_; path pp_[];
  k_=0;
  for q=ll: pp_[incr k_]=q; endfor
  i_=k_;
  for i=1 upto k_:
    (ta_[i], length pp_[i_]-tb_[i_]) =
      pp_[i] intersectiontimes reverse pp_[i_];
    if ta_[i]<0:
      message("[Error: area borders "& area_border[i] &" and "& 
         area_border[i_] &" don't intersect in scrap " & current_scrap &
         " (file " & current_src & ")]");
      area_border_errors := area_border_errors + 1;
    fi
    i_ := i;
  endfor
  for i=1 upto k_: subpath (ta_[i],tb_[i]) of pp_[i] .. endfor
    cycle
enddef;

vardef unitvector primary z = 
  if (z<>(0,0)):
    z/abs z 
  else:
    hide(thwarning("strange path"))
    (0,epsilon)
  fi
enddef;

def thwarning (expr m) = 
  message("[Warning: " & m & " in scrap " & current_scrap & "]");
enddef;

def check_area_borders = 
  if area_border_errors > 0:
  fi;
enddef;

%%%%%%%%%%%% Map symbols management %%%%%%%%%%%%%%%%%%%

def mapsymbol (expr name, set, warning) = 
  string s, stype, lname, ID;
  stype = substring (0,1) of name;
  lname = name & "_" & set;
  ID := "ID_" & lname;
  if (known scantokens ID):
    if stype = "a":
      s = "def " & name & " = scantokens(" & ditto & lname & ditto & ") enddef;";
    else:
      s = "let " & name & " = " & lname & ";";
    fi;
    scantokens s;
  elseif warning:  
    message("[Warning: undefined symbol `" & lname & "']");
  fi;
enddef;

%def hidesymbol (expr name) =
%  string s, stype;
%  stype = substring (0,1) of name;
%  if stype = "a":
%    s = "def " & name & " = scantokens(" & ditto & "a_empty" & ditto & ") enddef;";
%  else:
%    s = "vardef " & name & "@# (text t) = enddef;";
%  fi;
%  scantokens s;
%  write name to "missed.dat";
%enddef;

def initsymbol (expr name) =
  s := "ID_" & name & " = 1";
  scantokens s;
enddef;

%%%

% comment out groups in order to use 'save ATTR_*' appropriately

def beginfig(expr c) =
%  begingroup
  charcode:=c;
  clearxy; clearit; clearpen;
  pickup defaultpen;
  drawoptions();
  scantokens extra_beginfig;
  
  save smartll, smartur; 
  pair smartll[], smartur[]; 
  smart_count := 0;
enddef;

def endfig =
  scantokens extra_endfig;
  shipit;
%  endgroup
enddef;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% P. Bolek's MPATTERN package adapted and simplified for Therion
% (with the same user interface except of patterncolor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

string Pname_, PXYsteps_;
string Pmatrix_;

numeric Pnum_; Pnum_=0;

def PmakeBB_=
   PBBox_ := "[" & decimal Plft_ & " " & decimal Plow_ & " "
   & decimal Prt_ & " " & decimal Pup_ & "]";
enddef;

def Psteps_=
   PXYsteps_ := decimal
     if unknown PXStep_: (Prt_-Plft_) else: PXStep_ fi 
   & ":" & decimal
     if unknown PYStep_: (Pup_-Plow_) else: PYStep_ fi;
enddef;
   
vardef Pfindbounds_=
   Plow_ = ypart (llcorner currentpicture);
   Plft_ = xpart (llcorner currentpicture);
   Pup_ = ypart (urcorner currentpicture);
   Prt_ = xpart (urcorner currentpicture);
   PmakeBB_;
enddef;

def PmakePattern_(expr name)=
  write decimal (Pnum_*epsilon) & ":"
    & jobname & "." & decimal charcode & ":"
    & PBBox_ & ":"
    & PXYsteps_ & ":"
    & Pmatrix_ 
  to "patterns.dat"
enddef;

% User interface macros

vardef patternbbox(expr a)(text b)=
   save Pi_, Pz_;
   numeric Pi_, Pz_[];
   if pair a:
      Plft_:=min(xpart(a),xpart(b)); Plow_:=min(ypart(a),ypart(b));
      Prt_:=max(xpart(a),xpart(b));  Pup_:=max(ypart(a),ypart(b));
   else:
      Pi_=1;
      for t=b:
	 Pz_[Pi_]=t;
	 Pi_:=Pi_+1;
      endfor;
      Plft_:=min(a,Pz_2);   Plow_:=min(Pz_1,Pz_3);
      Prt_:=max(a,Pz_2); Pup_:=max(Pz_1,Pz_3);
   fi;
   PmakeBB_;
enddef;

def beginpattern(suffix name)=
  numeric PXStep_, PYStep_;
  numeric Plow_, Plft_, Pup_, Prt_;
  string PBBox_;
  Pmatrix_:="[1 0 0 1 0 0]";
  Pname_:=str name;
  Pnum_:=Pnum_+1;
  beginfig(Pnum_+4000);
enddef;

def endpattern=
  if unknown PBBox_:
     Pfindbounds_;
  fi;
  endfig;
  Psteps_;
  PmakePattern_(Pname_);
  scantokens(Pname_ & "=Pnum_;");
enddef;

picture pattpict;
color patterncolor_;
patterncolor_ := black;

primarydef p withpattern s=
  if known s:

    hide(pattpict := image(draw (0,0)--(10,10));
      for i within pattpict:
        patterncolor_ := (redpart i, greenpart i, bluepart i);
      endfor;)

    p withcolor (epsilon, 10*epsilon, s*epsilon)
    if known mpversion:
      if scantokens(mpversion)>=1.000: 
        withprescript(decimal redpart   patterncolor_ & " " &
                      decimal greenpart patterncolor_ & " " &
                      decimal bluepart  patterncolor_ & " THsetpatterncolor")
      fi;
    fi;
  else:
    p withcolor (1,0,0);
    message("Warning: undefined pattern ignored");
  fi;  
enddef;
   
def patterntransform expr t=
   Pmatrix_ := "[" & decimal xxpart t
              & " " & decimal yxpart t
              & " " & decimal xypart t
              & " " & decimal yypart t
              & " " & decimal xpart t
              & " " & decimal ypart t & "]";
enddef;

def patternxstep expr t=
   PXStep_ = t;
enddef;

def patternystep expr t=
   PYStep_ = t;
enddef;

def patternstep text t=
   if pair t:
      PXStep_ = xpart t;
      PYStep_ = ypart t;
   else:
      (PXStep_,PYStep_)=t;
   fi;
enddef;

def patterncolor expr t=
  message("Warning: patterncolor not supported in Therion");
enddef;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of pattern macros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% transparent rgb colors

numeric RGBnum; RGBnum=0;
string RGBname;

def def_transparent_rgb (suffix name)(expr r, g, b) =
  RGBnum := RGBnum+1;
  RGBname := str name;
  write decimal (RGBnum*epsilon) & ":"
    & decimal r & " "
    & decimal g & " "
    & decimal b 
  to "rgbcolors.dat";
  scantokens(RGBname & ":=RGBnum;");
enddef;

primarydef p withtransparentcolor s=
   p withcolor (epsilon, 12*epsilon, s*epsilon);
enddef;

def_transparent_rgb(tr_white, 1, 1, 1);
def_transparent_rgb(tr_blue, 0, 0, 1);
def_transparent_rgb(tr_black, 0, 0, 0);
def_transparent_rgb(tr_bg, 
               redpart background, greenpart background, bluepart background);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some useful macros from H. Hagen's MetaFun package
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

vardef paired (expr d) =
  if pair d : d else : (d,d) fi
enddef ;

primarydef p randomshifted s = 
  begingroup ; save ss ; pair ss ; ss := paired(s) ; 
  p shifted (-.5xpart ss + uniformdeviate xpart ss,
             -.5ypart ss + uniformdeviate ypart ss) 
  endgroup 
enddef ; 

primarydef p randomized s =
  (if path p : 
    for i=0 upto length(p)-1 :
      ((point       i    of p) randomshifted s) .. controls 
      ((postcontrol i    of p) randomshifted s) and 
      ((precontrol (i+1) of p) randomshifted s) .. 
    endfor 
    if cycle p : 
      cycle 
    else :
      ((point length(p) of p) randomshifted s) 
    fi
  elseif pair p :
    p randomshifted s  
  elseif color p :
    if color s : 
      (uniformdeviate redpart   s * redpart   p,
       uniformdeviate greenpart s * greenpart p,
       uniformdeviate bluepart  s * bluepart  p)  
    elseif pair s : 
      ((xpart s + uniformdeviate (ypart s - xpart s)) * p)  
    else :  
      (uniformdeviate s * p)  
    fi 
  else :
    p + uniformdeviate s  
  fi)  
enddef ; 

primarydef p llmoved d =
  ((llcorner p) shifted (-xpart paired(d),-ypart paired(d)))
enddef ;

primarydef p lrmoved d =
  ((lrcorner p) shifted (+xpart paired(d),-ypart paired(d)))
enddef ;

primarydef p urmoved d =
  ((urcorner p) shifted (+xpart paired(d),+ypart paired(d)))
enddef ;

primarydef p ulmoved d =
  ((ulcorner p) shifted (-xpart paired(d),+ypart paired(d)))
enddef ;

primarydef p smoothed d =
  (p llmoved (-xpart paired(d),0) -- p lrmoved (-xpart paired(d),0) {right} .. 
   p lrmoved (0,-ypart paired(d)) -- p urmoved (0,-ypart paired(d)) {up}    .. 
   p urmoved (-xpart paired(d),0) -- p ulmoved (-xpart paired(d),0) {left}  ..
   p ulmoved (0,-ypart paired(d)) -- p llmoved (0,-ypart paired(d)) {down}  .. cycle) 
enddef ;

vardef punked primary p = 
  (point 0 of p for i=1 upto length(p)-1 : -- point i of p endfor 
   if cycle p : -- cycle else : -- point length(p) of p fi)  
enddef ;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of MetaFun macros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% we input map symbol definitions




%%%%% INPUT thPoint %%%%%


%% therion source code
%%
%% This file defines macros for point map symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thPoint.mp,v $
%% $Revision: 1.8 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

pair U;

def p_stalactite_UIS(expr pos,theta,sc,al) =
    U:=(.15u, .4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
    thdraw (0,.15u) -- (.15u,.4u);
enddef;

def p_stalagmite_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
    thdraw (0,-.15u) -- (.15u,-.4u);
enddef;

def p_pillar_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.15u)--(0,-.15u);
    thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
    thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
enddef;

def p_curtain_UIS(expr pos,theta,sc,al) =
    U:=(.15u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    thdraw (0,.15u)--(0,0){dir 180}..(-.12u,-.11u)..{dir 0}(0,-.22u)--(0,-.4u);
enddef;

def p_helictite_UIS(expr pos,theta,sc,al) =
    U:=(.2u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,.4u)--(0,-.4u);
    p := (-.2u,.4u)---(-.2u,.1u){down}..{dir -10}(-.1u,0.02u)---origin;
    thdraw p;
    thdraw p reflectedabout (origin,(0,u)) reflectedabout (origin,(u,0));
enddef;

def p_sodastraw_UIS(expr pos,theta,sc,al) =
    U:=(.5u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u)--(.5u,.2u);
    pickup PenD;
    thdraw (-.4u,.2u)--(-.4u,0);
    thdraw (-.12u,.2u)--(-.12u,-.25u);
    thdraw (.02u,.2u)--(.02u,-.1u);
    thdraw (.23u,.2u)--(.23u,-.19u);
    thdraw (.35u,.2u)--(.35u,-.15u);
enddef;

def p_crystal_UIS (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := ((-.35*u,0)--(.35*u,0));
    thdraw p;
    thdraw p rotated (60);
    thdraw p rotated (120);
enddef;

def p_flowstone_UIS (expr pos,theta,sc,al)=
    U:=(.45u,.1u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := ((-.15*u,0)--(.15*u,0));
    thdraw p shifted (.3u,-.1u);
    thdraw p shifted (-.3u,-.1u);
    thdraw p shifted (0,.1u);
enddef;

def p_moonmilk_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.2u){up}..{dir -60}(-.18u,-.105u){dir 80}..
        {dir-80}(.18u,-.105u){dir 60}..{down}(.5u,-.2u);
enddef;

def p_wallcalcite_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.2u,-.2u)--(0,.1u)--(.2u,-.2u);
enddef;

def p_popcorn_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.2u)--(.5u,-.2u);
    pickup PenD;
    thdraw (-.3u,-.2u)--(-.3u,.1u);
    thdraw (0,-.2u)--(0,.1u);
    thdraw (.3u,-.2u)--(.3u,.1u);
    thfill fullcircle scaled .2u shifted (-.3u,.1u);
    thfill fullcircle scaled .2u shifted (0,.1u);
    thfill fullcircle scaled .2u shifted (.3u,.1u);
enddef;

def p_disk_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.2u,-.3u)--origin--(.2u,-.3u);
    p:=fullcircle scaled .3u shifted (0,.15u);
    thclean p;
    thdraw p;
enddef;

def p_gypsum_NSS (expr pos,theta,sc,al)=
    U:=(.25u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.25u,0)--(.25u,0);
    thdraw (0,-.25u)--(0,.25u);
enddef;

def p_aragonite_NSS (expr pos,theta,sc,al)=
    U:=(.3u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u)--(0,.3u);
    thdraw (0,-.1u){dir 40}..{dir 5}(.3u,.08u);
    thdraw (0,-.1u){dir 140}..{dir 175}(-.3u,.08u);
    thdraw (0,.2u){dir 30}..{dir 5}(.25u,.3u);
    thdraw (0,.2u){dir 150}..{dir 175}(-.25u,.3u);
enddef;


def p_cavepearl_SKBB (expr pos,theta,sc,al)=
    U:=(.25u,.25u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=fullcircle scaled .25u shifted (0,.16u);
    thdraw p;
    thdraw p rotated 120;
    thdraw p rotated 240;
enddef;

def p_gypsumflower_NSS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
%    thdraw (.2u,0){left}..(0,.2u)..(.25u,.35u)..(.5u,0)..
%        (.1u,-.3u)..{dir 125}(-.5u,.2u);
    thdraw (.18u,0){left}..(0,.15u)..(.2u,.3u)..(.4u,0)..
        (.15u,-.28u)..{dir 120}(-.4u,.15u);
enddef;

def p_rimstonepool_ASF (expr pos,theta,sc,al)=
    U:=(.4u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := (-.4u,.2u){dir -70}..{dir 70}(.4u,.2u);
    thfill buildcycle(p,((.5u,.1u)--(-.5u,.1u)));
    thdraw p;
enddef;

def p_rimstonedam_ASF (expr pos,theta,sc,al)=
    U:=(.4u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,.2u){dir -70}..{dir 70}(.4u,.2u);
enddef;

def p_anastomosis_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.4u,-.2u)--(-.3u,-.3u)--(0,.3u)--(.1u,.2u);
    thdraw p;
    thdraw p shifted (.3u,0);
enddef;

def p_karren_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.3u){dir -85}..{dir 85}(-.32u,-.3u)..(-.28u,.3u){dir 85}..
        {dir -85}(-.12u,.3u)..(-.08u,-.3u){dir-85}..{dir 85}(.08u,-.3u)..
        {dir85}(.12u,.3u)..(.28u,.3u){dir -85}..(.32u,-.3u){dir -85}..
        {dir 85}(.5u,-.3u);
enddef;

def p_scallop_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-.4u){dir 125}..{dir 105}(-.2u,.1u){up}..
        {down}(.2u,.1u){dir -105}...{dir -125}(0,-.4u);
enddef;

def p_flute_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u)--(.5u,.2u);
    thdraw (-.3u,.2u){dir -70}..{dir 70}(.3u,.2u);
enddef;

def p_raft_NSS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,.2u){dir -80}..(-.3u,-.2u)..origin..(.3u,.2u)..
        {dir -80}(.5u,-.2u);
enddef;

def p_raftcone_NSS (expr pos,theta,sc,al)=
    U:=(.3u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.4u)--(0,.4u)--(.3u,-.4u);
enddef;

def p_spring_SKBB (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,.2u){down}..(0,-.2u)..{up}(.3u,.2u);
enddef;

def p_sink_SKBB (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,-.2u){up}..(0,.2u)..{down}(.3u,-.2u);
enddef;

def p_narrowend_UIS (expr pos,theta,sc,al)=
    U:=(.1u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.1u,-.4u)--(-.1u,.4u);
    thdraw (.1u,-.4u)--(.1u,.4u);
enddef;

def p_lowend_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.1u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,-.1u)--(.4u,-.1u);
    thdraw (-.4u,.1u)--(.4u,.1u);
enddef;

def p_lowend_NSS (expr pos,theta,sc,al)=
    U:=(.4u,0);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,0)--(.4u,0);
enddef;

def p_flowstonechoke_NSS (expr pos,theta,sc,al)=
    U:=(.4u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.4u,-.4u){right}..{dir120}(-.2u,-.2u){dir -20}..{up}(0,0);
    thdraw p;
    thdraw p shifted (0,.2u);
    thdraw p reflectedabout (origin,down);
    thdraw p reflectedabout (origin,down) shifted (0,.2u);
enddef;

def p_breakdownchoke_NSS (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.1u)--(-.15u,.05u)--(-.48u,.2u)--cycle;
    thdraw (-.2u,-.2u)--(.15u,-.18u)--(-.08u,.14u)--cycle;
    thdraw (.1u,0)--(.4u,-.1u)--(.5u,.2u)--(.1u,.2u)--cycle;
enddef;

def p_bedrock_ASF (expr pos,theta,sc,al)=
    U:=(.5u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,0)--(.5u,0);
    thdraw (-.3u,0)--(-.3u,.2u);
    thdraw (.3u,0)--(.3u,-.2u);
enddef;

def p_sand_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenB;
    thdraw (0,.2u);
    thdraw (0,.2u) rotated 120;
    thdraw (0,.2u) rotated 240;
enddef;

def p_clay_SKBB (expr pos,theta,sc,al) =
    U:=(.3u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,0){up}..origin{down}..{up}(0.3u,0);
enddef;

def p_pebbles_UIS (expr pos,theta,sc,al)=
    U:=(.45u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75);
    thdraw p rotated 20 shifted (0,.25u);
    thdraw p rotated -37 shifted (.25u,-.25u);
    thdraw p rotated -62 shifted (-.25u,-.25u);
enddef;

def p_debris_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.4u)--(0,-.22u)--(-.4u,-.1u)--cycle;
    thdraw (.2u,-.4u)--(.4u,-.1u)--(.1u,-.1u)--cycle;
    thdraw (-.1u,0)--(.2u,.3u)--(-.2u,.3u)--cycle;
enddef;

def p_blocks_UIS (expr pos,theta,sc,al)=
    U:=(.5u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.5u,-.5u)--(.3u,-.4u)--(-.17u,.2u)--cycle;
    thdraw (.25u,-.25u)--(.5u,-.15u)--(.3u,.5u)--(-.1u,.5u)--cycle;
    thdraw (-.27u,0)--(-.1u,.3u)--(-.5u,.35u)--cycle;
    pickup PenD;
    thdraw (-.5u,-.5u)--(-.1u,-.2u)--(-.17u,.2u);
    thdraw (-.1u,-.2u)--(.3u,-.4u);
    thdraw (.25u,-.25u)--(.3u,0)--(.2u,.2u)--(-.1u,.5u);
    thdraw (.3u,.5u)--(.2u,.2u);
    thdraw (.5u,-.15u)--(.3u,0);
enddef;

def p_water_UIS (expr pos,theta,sc,al)=
    U:=(.425u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenD;
    p:=fullcircle xscaled (.85u) yscaled (.6u);
    thfill p withpattern pattern_water_UIS;
    thdraw p;
enddef;

def p_ice_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := (0,.05u)--(0,.35u);
    thdraw p;
    thdraw p shifted (-.25u,-.3u);
    thdraw p shifted (.25u,-.3u);
    p := (-0.15u,.2u)--(0.15u,.2u);
    thdraw p;
    thdraw p shifted (-.25u,-.3u);
    thdraw p shifted (.25u,-.3u);
enddef;

def p_snow_SKBB (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := origin--(0,.25*u);
    q := ((0,.35u)--(0,0.25u)--(0.1u,0.25u)) rotatedaround ((0,0.25u),45);
    thdraw p;
    thdraw p rotated (60);
    thdraw p rotated (120);
    thdraw p rotated (180);
    thdraw p rotated (240);
    thdraw p rotated (300);
    thdraw q;
    thdraw q rotated (60);
    thdraw q rotated (120);
    thdraw q rotated (180);
    thdraw q rotated (240);
    thdraw q rotated (300);
enddef;


def p_archeomaterial_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p := fullcircle scaled .8u; 
    thdraw (-.5u,-.5u)--origin cutbefore p;
    thdraw (-.5u,.5u)--origin cutbefore p;
    thdraw origin--(.4u,0);
    thdraw p;
enddef;

def p_paleomaterial_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.4u,-.2u)..(-.2u,-.08u)---(-.1u,.05u)---(0,.2u)..(-.03u,.4u)..
        (.2u,.3u)..(.35u,.25u)..(.2u,.2u)---origin---(-.1u,-.17u)..
        (-.08u,-.25u){dir -120}..(-.3u,-.23u)
        ..cycle;
enddef;

def p_guano_UIS (expr pos,theta,sc,al)=
    U:=(.4u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.4u,.2u){dir 40}..{down}(0,-.35u){up}..{dir-40}(.4u,.2u);
enddef;

def p_vegetabledebris_ASF (expr pos,theta,sc,al)=
    U:=(.38u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.3u)--(0,.3u);
    thdraw (0,-.3u)--(.3u,.3u);
    thdraw (-.25u,.13u)--(.38u,.13u);
    thdraw (-.38u,-.13u)--(.25u,-.13u);
enddef;

def p_root_ASF (expr pos,theta,sc,al)=
    U:=(.1u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.1u,-.5u)--(-.1u,.5u);
    p:=(-.1u,-.3u)--(.1u,-.5u);
    thdraw p;
    thdraw p shifted (0,.2u);
    thdraw p shifted (0,.4u);
enddef;

def p_entrance_UIS (expr pos,theta,sc,al)=
    U:=(.2u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.2u,-.5u)--(0,.5u)--(.2u,-.5u)--cycle;
enddef;

def p_waterflow_paleo_UIS (expr pos,theta,sc,al)=
    U:=(.2u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-u)--(0,u);
    thdraw halfcircle scaled .4u shifted (0,-.4u);
    p:=(-.15u,.6u)--(0,u)--(.15u,.6u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_gradient_UIS (expr pos,theta,sc,al)=
    U:=(.15u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-u)--(0,u);
    p:=(-.15u,.6u)--(0,u)--(.15u,.6u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_gradient_BCRA (expr pos,theta,sc,al)=
    U:=(.25u,0.7u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thfill (-.25u,-0.7u)--(0,.7u)--(.25u,-.7u)--cycle;
enddef;

% by Philip Schuchardt
def p_gradient_NSS (expr pos,theta,sc,al) =
  U:=(.7u, .6u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;

  thdraw (-.3u, -.5u) -- (-.7u, -.2u);
  thdraw (-.2u, -.4u) -- (-.4u, .3u);
  thdraw (0u, -.3u) -- (0u, .6u);
  thdraw (.3u, -.5u) -- (.7u, -.2u);
  thdraw (.2u, -.4u) -- (.4u, .3u);
enddef;

def p_waterflow_permanent_UIS (expr pos,theta,sc,al)=
    U:=(.15u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(0,.5u){down}..(.12u,.3u)..(-.15u,.15u)..(.13u,0)..
        (-.08u,-.2u)..{down}(0,-.5u);
    p:=p rotated 180;
    thdraw p;
    thdrawoptions();
    oldahlength:=ahlength; ahlength:=2.5pt*optical_zoom;
    thdraw arrowhead p;
    thfill arrowhead p;
    ahlength:=oldahlength;
enddef;

def p_waterflow_intermittent_UIS (expr pos,theta,sc,al)=
  thdrawoptions(dashed evenly scaled (.5 * optical_zoom));
  p_waterflow_permanent_UIS (pos,theta,sc,al);
  thdrawoptions();
enddef;

def p_airdraught_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
	p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
	thdraw p;
	thdraw p reflectedabout (origin,(0,u));
	for i:=1 upto round(3+2*mlog(sc)/mlog 2):
	  thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
	endfor;
enddef;

def p_airdraught_winter_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
  p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
  thdraw p;
  thdraw p reflectedabout (origin,(0,u));
  for i:=1 upto round(3+2*mlog(sc)/mlog 2):
    thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
  endfor;
  thclean fullcircle scaled 0.6u shifted (0,0.05u);
  thdraw (-0.1732u,-0.05u) -- (0.1732u,0.15u);
  thdraw (0.1732u,-0.05u) -- (-0.1732u,0.15u);
  thdraw (0,-0.15u) -- (0,0.25u);
enddef;

def p_airdraught_summer_UIS (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,u)--(0,-0.8u);
  p:=(-.2u,.65u){dir 20}..{dir 90}(0,u);
  thdraw p;
  thdraw p reflectedabout (origin,(0,u));
  for i:=1 upto round(3+2*mlog(sc)/mlog 2):
    thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
  endfor;
  thclean fullcircle scaled 0.6u shifted (0,0.05u);
  thdraw (-0.1732u,-0.05u) -- (0.1732u,0.15u);
  thdraw (0.1732u,-0.05u) -- (-0.1732u,0.15u);
  thdraw (0,-0.15u) -- (0,0.25u);
  thclean fullcircle scaled 0.3u shifted (0,0.05u);
  thdraw fullcircle scaled 0.2u shifted (0,0.05u);
enddef;


def p_station_fixed_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    pair z;
    z:=(0,.2u);
    thclean z -- (z rotated 120) -- (z rotated 240) -- cycle;
    thdraw z -- (z rotated 120) -- (z rotated 240) -- cycle;
    thdraw origin;
enddef;

def p_station_painted_SKBB (expr pos)=
    T:=identity shifted pos;
    pickup PenC;
    thclean fullcircle scaled 0.25u;
    thdraw fullcircle scaled 0.25u;
enddef;

def p_station_natural_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    thclean fullcircle scaled .3u;
    thdraw fullcircle scaled .3u;
    thdraw origin;
enddef;

def p_station_temporary_ASF (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    p:=(-.2u,0)--(.2u,0);
    thdraw p;
    thdraw p rotated 90;
    thclean fullcircle scaled .16u;
    pickup PenC;
    thdraw origin;
enddef;

let p_station_temporary_SKBB = p_station_painted_SKBB;

def p_steps_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.3u,.3u)--(-.3u,.1u)--(-.1u,.1u)--(-.1u,-.1u)--
           (.1u,-.1u)--(.1u,-.3u)--(.3u,-.3u);
enddef;

def p_fixedladder_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.15u,-.4u)--(-.15u,.4u);
    thdraw (.15u,-.4u)--(.15u,.4u);
    thdraw (-.15u,0)--(.15u,0);
    thdraw (-.15u,.2u)--(.15u,.2u);
    thdraw (-.15u,-.2u)--(.15u,-.2u);
enddef;

def p_ropeladder_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (.1u,-.4u)..(.2u,-.2u)..(.1u,.2u)..(.2u,.4u);
    thdraw (-.2u,-.4u)..(-.1u,-.2u)..(-.2u,.2u)..(-.1u,.4u);
    thdraw (-.2u,.2u)--(.1u,.2u);
    thdraw (-.15u,0)--(.15u,0);
    thdraw (-.1u,-.2u)--(.2u,-.2u);
enddef;

def p_bridge_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.3u,.2u)--(-.2u,.1u)--(.2u,.1u)--(.3u,.2u);
    thdraw (-.3u,-.2u)--(-.2u,-.1u)--(.2u,-.1u)--(.3u,-.2u);
enddef;

def p_noequipment_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    thfill (0,-.1u)--(-.05u,.3u)--(.05u,.3u)--cycle;
    thdraw (0,-.2u) withpen PenX;
enddef;

def p_anchor_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    thdraw fullcircle scaled .2u shifted (0.2u,0) withpen PenC;
    begingroup;
      interim linecap:=butt;
      thdraw (-.3u,0)--(.1u,0) withpen PenA;
    endgroup;
    thdraw (.1u,-.4u)--(.1u,.4u) withpen PenD;
enddef;

def p_traverse_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.25u,.05u)..(0,-.08u)..(.25u,.05u);
    pickup pencircle scaled .18u;
    thdraw (-.25u,.05u);
    thdraw (.25u,.05u);
enddef;

def p_rope_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.2u,.2u)..origin..(.1u,.1u)--(.1u,-.4u);
    pickup pencircle scaled .18u;
    thdraw (-.2u,.2u);
    thdraw (.1u,.1u);
enddef;

def p_camp_SKBB (expr pos,r,s,al) = 
    U:=(.4u, .5u);
    T:=identity aligned al shifted pos;
    pickup PenC;
    thdraw (-.4u,-.4u)--(0,.5u)--(.4u,-.4u)--cycle;
    pickup PenD;
    thdraw (0,-.4u)--(0,.5u);
enddef;


def p_dig_UIS (expr pos,r,s,al) = 
    U:=(.4u, .5u);
    T:=identity aligned al shifted pos;
    thfill ((-.075u,-.5u){down} .. {up}(0.075u, -.5u) -- (0.075u, .15u) -- (0.3u, 0.15u) -- (0.3u, 0.5u) --
    (-.3u, .5u) -- (-.3u, .15u) -- (-.075u, .15u) -- cycle) rotated 45;
enddef;

def p_continuation_UIS(expr pos,theta,sc,al) =
  U:=(.15u,.3u);
  T:=identity aligned al shifted pos;
  pickup PenC;
  thdraw (-.1u,.2u){up}..{down}(.1u,.2u)..{down}(0,-.05u);
  pickup PenX;
  thdraw (0,-.2u);
enddef;

def p_station_SKBB(expr pos,mark,txt)(text flags) =
  T:=identity shifted pos;

  if mark=4: p_station_fixed(pos)
  elseif mark=3: p_station_natural(pos)
  elseif mark=2: p_station_painted(pos)
  elseif mark=1: p_station_temporary(pos)
  fi;
  
  path path_cave;
  path_cave = (-.3u,-.25u) -- (-.2u,-.25u){dir 135} .. (0, .25u) .. {dir 225}(.2u,-.25u) -- (.3u,-.25u);
  for i=flags:
    pickup PenX;
    if i="entrance":
%      thfill fullcircle scaled 1 cm withtransparentcolor tr_blue;
      thdraw path_cave;
%      p_label.urt(txt,pos+(0.4u,0),0,0);
      if not numeric txt:
        p_smartlabel(txt,pos);
      fi;
    elseif i="sink":
      thdraw path_cave cutbefore ((-u,0)--(u,0)) cutafter ((-u,0)--(u,0));
      pickup PenA;
      thdraw (0,-.45u) -- (0,.05u) withcolor blue;
      thdraw (-.15u,-.02u) -- (0,.05u) -- (.15u,-.02u) withcolor blue;
    elseif i="spring":
      thdraw path_cave cutbefore ((-u,0)--(u,0)) cutafter ((-u,0)--(u,0));
      pickup PenA;
      thdraw (0,-.45u) -- (0,.05u) withcolor blue;
      thdraw (-.15u,-.38u) -- (0,-.45u) -- (.15u,-.38u) withcolor blue;
    elseif i="doline":
      thdraw (-.5u,.05u){down}..(0,-0.6u)..{up}(.5u,.05u);
    elseif i="dig":
      thdraw (-.5u,.25u) -- (-.35u,.25u)--(-.23u,-.25u)--(.23u,-.25u)--(.35u,.25u)--(.5u,.25u);
    elseif substring(0,11) of i = "air-draught":
      pickup PenB;
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u));
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u)) shifted (.11u,0);
      thdraw ((0,.11u){dir-120} ..{dir-70}(0,0) .. {dir-120}(0,-.11u)) shifted (-.11u,0);
    elseif i="continuation":
      if picture(txt):
        picture ATTR__text;
        ATTR__text := txt;
      fi;
      begingroup;
        save T; transform T;
        p_continuation(pos+(0,.25u),0,1,(0,1));
      endgroup;
      if picture(txt):
        save ATTR__text;
      fi;
    elseif i="arch":
      thdraw (-.5u,-.25u)--(-.5u,.25u)--(.5u,.25u)--(.5u,-.25u)..(0,.2u)..cycle;
      thfill (-.5u,-.25u)--(-.5u,.25u)--(.5u,.25u)--(.5u,-.25u)..(0,.2u)..cycle;
    elseif i="overhang":
      thdraw (.2u,-.25u)--(-.2u,-.25u){up}..{right}(.2u,.25u);
    fi;
  endfor;
%  thdraw (0,0) withpen PenX withcolor red;
enddef;

def p_debug (expr col, pen, pos)=
    T:=identity shifted pos;
    thdraw origin withpen pencircle 
      scaled if pen=0: 2pt 
                 else: 4pt fi 
      withcolor if col=-2: (1,.85,0)
           elseif col=-1: black 
           elseif col=0: red 
           else: blue fi;
enddef;


def p_u(expr pos,theta,sc,al) =
  T:=identity shifted pos;
  thdraw origin withpen pencircle scaled 4pt withcolor red;
enddef;

def p_handrail_SKBB(expr pos,theta,sc,al) =
    tmph := 1 / Scale * 72 / 2.54;  % 1 m height
    U:=(.1u, tmph);
    pickup PenC;
    T:=identity aligned al rotated theta scaled sc shifted pos;
    thdraw (0,0) -- (0,tmph);
    thdraw (0,tmph) withpen pencircle scaled .25u;    
enddef;

def p_viaferrata_SKBB(expr pos,r,s,al) = 
    U:=(.4u, .4u);
    T:=identity aligned al shifted pos;
    thdraw unitsquare scaled .8u shifted (-0.4u,-.4u) withpen PenD;
    pickup PenC;
    thdraw (-.15u,.15u)--(-.15u,.1u)--(.15u,.1u)--(.15u,.15u);
    thdraw (-.15u,-.05u)--(-.15u,-.1u)--(.15u,-.1u)--(.15u,-.05u);
enddef;

def p_stalagmites_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
        thdraw (0,-.15u) -- (.15u,-.4u);
    endfor;
enddef;

def p_stalactites_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
        thdraw (0,.15u) -- (.15u,.4u);
    endfor;
enddef;

def p_gradient_SKBB (expr pos,theta,sc,al)=
    U:=(.3u,.6u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (-.3u,-.6u)--(-.3u,.6u);
    thdraw (0,-.6u)--(0,-0.2u);
    thdraw (.3u,-.6u)--(.3u,.6u);
enddef;

def p_pillars_UIS(expr pos,theta,sc,al) =
    U:=(.3u, .2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    for i=-1 upto 1:
        T:=identity aligned al rotated theta scaled (sc * 0.7) shifted (pos + (i * .3u, 0));
        thdraw (0,.15u)--(0,-.15u);
        thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
        thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    endfor;
enddef;





%%%%% ENDINPUT thPoint %%%%%





%%%%% INPUT thLine %%%%%


%% therion source code
%%
%% This file defines macros for line symbols
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thLine.mp,v $
%% $Revision: 1.4 $
%%
%% Copyright (C) 2000 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

% some definitions

% adjust step according to the length of the path; return at least two steps

vardef adjust_step (expr len, s) =
  if s <= len/2: len / (floor(len / s))
  else: len/2 fi
enddef;

def mark_(expr p,t,l) =
  thdraw (point t of p) --
          ((point t of p) + l * unitvector(thdir(p,t) rotated 90));
enddef;

vardef thdir (expr p,t) =    % 1 * epsilon caused problems in scales < 1:1000
                             % n * epsilon is enough for scale 1:(n*1000)
  if arclength(p)=0:
    hide(thwarning("unable to determine direction on zero-length path"))
    (0,1)
  else:
%  ((direction t-100*epsilon of p) + (direction t+100*epsilon of p)) / 2
   postcontrol (t+1000*epsilon) of p - precontrol (t-1000*epsilon) of p
%  direction t of p
  fi
enddef;

% walls:

def l_wall_bedrock_UIS (expr P) = 
  T:=identity;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_sand_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.1u);
  pickup PenB;  
  forever:
    t := arctime cas of P;
    thdraw ((point t of P) + (uniformdeviate 1) * .4u 
            * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenA;  
  thdraw P;
enddef;

def l_wall_pebbles_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .35u);
  pickup PenC;
  q:=superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/20) rotated (angle(thdir(P,t)) + (normaldeviate*40)) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_wall_clay_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .5u);
  pickup PenC;
  q := (-0.15u,0){up}..{down}origin..{up}(0.15u,0);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  pickup PenA;  
  thdraw P;
enddef;

def l_wall_debris_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .4u);
  pickup PenC;
%  q := ((-.1u,-.15u)--(.2,.03u)--(-.2u,.15u)--cycle) scaled 1.5;
  q := ((-.2u,-.1u)--(.2u,-.1u)--(0,.2u)--cycle) scaled 1.1;
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/10) rotated uniformdeviate (360) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_wall_blocks_SKBB (expr P) = 
%  pickup PenD;
%  draw P withcolor red;

  T:=identity;
  cas := 0;
  dlzka := arclength P;
if dlzka > 0:
  mojkrok:=adjust_step(dlzka, 1.5u);
  pickup PenA;
  forever:
    t1 := arctime (cas + mojkrok*1/10) of P;
    t2 := arctime (cas + mojkrok*9/10) of P;
    q := ((point t1 of P) + .4u * unitvector(thdir(P,t1) rotated -90)) --
         (subpath (t1,t2) of P) --
         ((point t2 of P) + .4u * unitvector(thdir(P,t2) rotated -90));
    thdraw q randomized (u/6);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
fi;
enddef;

def l_wall_ice_SKBB (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .5u);
  pickup PenC;
  p := (-.1u,0)--(.1u,0);
  q := (0,-.1u)--(0,.1u);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw p shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    thdraw q shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  pickup PenA;  
  thdraw P;
enddef;

def l_wall_underlying_UIS (expr P) = 
  T:=identity;
  pickup PenA;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_wall_unsurveyed_SKBB (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P;
enddef;

def l_wall_presumed_UIS (expr P) = 
  T:=identity;
  pickup PenA;
  thdraw P dashed evenly scaled (2*optical_zoom);
enddef;

% other line symbols

def l_pit_UIS (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.25u);
  pickup PenD;  
  forever:
    t := arctime cas of P;
    mark_ (P,t,0.2u);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenC;  
  thdraw P;
enddef;

let l_floorstep_UIS = l_pit_UIS;

def l_overhang_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.3u);
  pickup PenC;
  t1:=0;
  forever:
    t := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok) of P;
    thfill (subpath (t1,t2) of P) -- 
      ((point t of P) + .3u * unitvector(thdir(P,t) rotated 90)) -- 
      cycle;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
    t1:=t2;
  endfor;
  thdraw P;
enddef;


def l_chimney_UIS (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_ceilingstep_SKBB (expr P) =
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);
  pickup PenC;
  forever:
    t1 := arctime (cas + mojkrok*1/5) of P;
    t  := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok*4/5) of P;
    thdraw (subpath (t1,t2) of P);
    mark_ (P,t,0.2u);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

def l_ceilingmeander_SKBB (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);
  pickup PenC;
  forever:
    t  := arctime (cas + mojkrok/2) of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.1u * Pv) --
          (Pp + 0.2u * Pv);
    thdraw (Pp + 0.2u * Pv + 0.2u * Pd) --
          (Pp + 0.2u * Pv - 0.2u * Pd);
    thdraw (Pp - 0.1u * Pv) --
          (Pp - 0.2u * Pv);
    thdraw (Pp - 0.2u * Pv + 0.2u * Pd) --
          (Pp - 0.2u * Pv - 0.2u * Pd);
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;


%Bruce Mutton 2012.06.16 uses general code for l_ceilingmeander_SKBB defined in therion source code by Martin Budaj 5.3.9
% but ticks on outside (rock) side of lines 
def l_ceilingmeander_UIS (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  T:=identity;
  cas := 0;                           % cursor to step along path
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);  % symbol length nudged to be multiple of path length
  pickup PenC;
  forever:
    t  := arctime (cas + mojkrok/2) of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.2u * Pv) --
          (Pp + 0.3u * Pv);              % add 0.1u to each moves ticks outside
    thdraw (Pp + 0.2u * Pv + 0.2u * Pd) --
          (Pp + 0.2u * Pv - 0.2u * Pd);  
    thdraw (Pp - 0.2u * Pv) --
          (Pp - 0.3u * Pv);              % subtract 0.1u to each moves ticks outside
    thdraw (Pp - 0.2u * Pv + 0.2u * Pd) --
          (Pp - 0.2u * Pv - 0.2u * Pd); 
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3);  % for rounding errors
  endfor;
enddef;

let l_ceilingmeander_NZSS = l_ceilingmeander_UIS;

%Bruce Mutton 2012.06.16 uses general code for l_ceilingstep_SKBB defined in therion source code by Martin Budaj 5.3.9
% but ticks on righthand (rock) side of line 
def l_ceilingstep_UIS (expr P) =
  T:=identity;
  cas := 0;                            % cursor to step along path
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.8u);   % symbol length nudged to be multiple of path length
  pickup PenC;
  forever:
    t1 := arctime (cas + mojkrok*1/5) of P;
    t  := arctime (cas + mojkrok/2) of P;
    t2 := arctime (cas + mojkrok*4/5) of P;
    thdraw (subpath (t1,t2) of P);
    mark_ (P,t,-0.2u);                  % change sign to -0.2u
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;

let l_ceilingstep_NZSS = l_ceilingstep_UIS;

%Bruce Mutton 2012.06.10 uses general code for l_pit_UIS defined in therion source code by Martin Budaj 5.3.9
% dots on righthand (rock) side of line spaced 0.2u, 0.2u same as floor-step ticks
def l_chimney_NZSS (expr P) = 
	T:=identity;
	cas := 0;                            % cursor to step along path
	dlzka := arclength P;
	mojkrok:=adjust_step(dlzka, 0.25u);  % symbol length nudged to be multiple of path length
	q:= (0.20u,-0.20u) -- (0.21u,-0.21u);         % dot

	pickup PenC;  %2nd thinnest pen
	forever:
	  t := arctime cas of P;
	thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % draw dots
	cas := cas + mojkrok;
	  exitif cas > dlzka + (mojkrok / 3); % for rounding errors
	endfor;
	pickup PenB;   %2nd thickest pen
	thdraw P;      %continuous line
enddef;

%Bruce Mutton 2010.06.20 uses general code and adjust_step defined in therion source code by Martin Budaj
%for Therion 5.3.8
def l_wall_presumed_NZSS (expr P) =
	T:=identity;
	cas := 0;                                 % cursor to step along path
	dlzka := arclength P;
	mojkrok:=adjust_step(dlzka, 1.5u);        % symbol length nudged to be multiple of path length
	q  := (-0.2u,-0.4u)--(0,0)--(0.2u,-0.4u); % define v shape 
	forever:
	  t1 := arctime (cas + mojkrok*1/5) of P;
	  t  := arctime (cas + mojkrok/2) of P;
	  t2 := arctime (cas + mojkrok*4/5) of P;
		pickup PenA;                          % thick
	thdraw (subpath (t1,t2) of P);          % dash
	  pickup PenC;                          % thin
	  thdraw q rotated angle(thdir(P,t)) shifted (point t of P ); % v shape

	  cas := cas + mojkrok;
	  exitif cas > dlzka - (2*mojkrok/3);     % for rounding errors
	endfor;
enddef;

def l_floormeander_SKBB (expr P) =
  pair Pp;
  pair Pd;
  pair Pv;
  pair PPp;
  pair PPd;
  pair PPv;

  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.25u);
  pickup PenC;
  forever:
    t := arctime cas of P;
    Pp := (point t of P);
    Pd := unitvector(thdir(P,t));
    Pv := Pd rotated 90;
    thdraw (Pp + 0.1u * Pv) --
          (Pp + 0.2u * Pv);
    thdraw (Pp - 0.1u * Pv) --
          (Pp - 0.2u * Pv);
    if cas > 0:
      thdraw (PPp + 0.2u * PPv) --
          (Pp + 0.2u * Pv);
      thdraw (PPp - 0.2u * PPv) --
          (Pp - 0.2u * Pv);
    fi;
    PPp := Pp;
    PPd := Pd;
    PPv := Pv;
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
enddef;    

boolean alw_perpendicular;

def l_slope_SKBB (expr P,S)(text Q) = 
%show Q;
  T:=identity;
  numeric dirs[];
  numeric lengths[];
  for i=Q:
    dirs[redpart i]:=greenpart i;
    lengths[redpart i]:=bluepart i;
  endfor;  


  li:=length(P); % last

  alw_perpendicular:=true;

  for i=0 upto li:
    if unknown dirs[i]: dirs[i]:=-1; 
    else: 
      if dirs[i]>-1:
        dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360; 
        alw_perpendicular:=false;
      fi;
    fi;
    if unknown lengths[i]: lengths[i]:=-1; fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    d:=dirs[i];
    if d=-1:
      if (i=0) or (i=li):
        dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
	pi:=i;
      else:
        if ni<=i:
	  for j=i upto li:
            ni:=j;
	    exitif dirs[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	dirs[i]:=w[dirs[pi],dirs[ni]];
%        if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%          dirs[i]:=w[dirs[ni],dirs[pi]];
%	  message("*******");
%        fi;
     fi;
    else:
      pi:=i;
    fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    l:=lengths[i];
    if l=-1:
      if (i=0) or (i=li):
        lengths[i] := 1cm; % should never happen!
	thwarning("slope width at the end point not specified");
	pi:=i;
      else:
        if ni<=i:
	  for j=i+1 upto li:
            ni:=j;
	    exitif lengths[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	lengths[i]:=w[lengths[pi],lengths[ni]];
	pi:=i;
      fi;
    else:
      pi:=i;
    fi;
  endfor;

% for i=0 upto li: show lengths[i]; endfor;

  T:=identity;
  boolean par;
  offset:=0;
  dlzka := (arclength P);
  if dlzka>3u: 
    offset := 0.3u;
  elseif dlzka>u:
    offset := 0.1u;
  fi;
  dlzka:=dlzka-2offset;
  cas := offset;
  mojkrok:=adjust_step(dlzka,1.4u) / 2;
  pickup PenD;
  par := false; 
  forever:
    t := arctime cas of P;
    if t mod 1>0:  % not a key point
      w := (arclength(subpath(floor t,t) of P) / 
            arclength(subpath(floor t,ceiling t) of P));
      if alw_perpendicular:
        a := 90;
      else:
        a := w[dirs[floor t],dirs[ceiling t]];
      fi;
      l := w[lengths[floor t],lengths[ceiling t]];
    else:
      if alw_perpendicular:
        a := 90;
      else:
        a:= dirs[t];
      fi; 
      l:=lengths[t];
    fi;
    
    a := a + angle(thdir(P,t));
    
    thdraw (point t of P) -- 
      ((point t of P) + if par: 0.333 * fi l * unitvector(dir(a)));
    cas := cas + mojkrok;
    par := not par;
    exitif cas > dlzka + offset + 0.1mm;  % for rounding errors
  endfor;
  if S = 1: pickup PenC; draw P fi;
%pickup pencircle scaled 3pt;
%for i=0 upto li: draw point i of P; endfor;
enddef;


def l_slope_BCRA (expr P,S)(text Q) = 
%show Q;
  T:=identity;
  numeric dirs[];
  numeric lengths[];
  for i=Q:
    dirs[redpart i]:=greenpart i;
    lengths[redpart i]:=bluepart i;
  endfor;  


  li:=length(P); % last

  alw_perpendicular:=true;

  for i=0 upto li:
    if unknown dirs[i]: dirs[i]:=-1; 
    else: 
      if dirs[i]>-1:
        dirs[i]:=((90-dirs[i]) - angle(thdir(P,i))) mod 360; 
        alw_perpendicular:=false;
      fi;
    fi;
    if unknown lengths[i]: lengths[i]:=-1; fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    d:=dirs[i];
    if d=-1:
      if (i=0) or (i=li):
        dirs[i] := angle(thdir(P,i) rotated 90) mod 360;
	pi:=i;
      else:
        if ni<=i:
	  for j=i upto li:
            ni:=j;
	    exitif dirs[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	dirs[i]:=w[dirs[pi],dirs[ni]];
%        if (dirs[i]-angle(thdir(P,i))) mod 360>180:
%          dirs[i]:=w[dirs[ni],dirs[pi]];
%	  message("*******");
%        fi;
     fi;
    else:
      pi:=i;
    fi;
  endfor;

%for i=0 upto li: show dirs[i]; endfor;

  ni:=0; % next
  pi:=0; % previous

  for i=0 upto li:
    l:=lengths[i];
    if l=-1:
      if (i=0) or (i=li):
        lengths[i] := 1cm; % should never happen!
	thwarning("slope width at the end point not specified");
	pi:=i;
      else:
        if ni<=i:
	  for j=i+1 upto li:
            ni:=j;
	    exitif lengths[j]>-1;
	  endfor;
	fi;
	w:=arclength(subpath(pi,i) of P) / 
	   arclength(subpath(pi,ni) of P);
	lengths[i]:=w[lengths[pi],lengths[ni]];
	pi:=i;
      fi;
    else:
      pi:=i;
    fi;
  endfor;

% for i=0 upto li: show lengths[i]; endfor;

  T:=identity;
  boolean par;
  offset:=0;
  dlzka := (arclength P);
  if dlzka>3u: 
    offset := 0.3u;
  elseif dlzka>u:
    offset := 0.1u;
  fi;
  dlzka:=dlzka-2offset;
  cas := offset;
  mojkrok:=adjust_step(dlzka,1.4u) / 2;
  pickup PenD;
  par := false; 
  forever:
    t := arctime cas of P;
    if t mod 1>0:  % not a key point
      w := (arclength(subpath(floor t,t) of P) / 
            arclength(subpath(floor t,ceiling t) of P));
      if alw_perpendicular:
        a := 90;
      else:
        a := w[dirs[floor t],dirs[ceiling t]];
      fi;
      l := w[lengths[floor t],lengths[ceiling t]];
    else:
      if alw_perpendicular:
        a := 90;
      else:
        a:= dirs[t];
      fi; 
      l:=lengths[t];
    fi;
    
    a := a + angle(thdir(P,t));
    
    if par:
      thfill (point t of P) + mojkrok/2.5 * unitvector(dir(a+90))-- 
        ((point t of P) + l * unitvector(dir(a))) --
        (point t of P) + mojkrok/2.5 * unitvector(dir(a-90)) -- cycle;
    fi;
    cas := cas + mojkrok;
    par := not par;
    exitif cas > dlzka + offset + 0.1mm;  % for rounding errors
  endfor;
enddef;


def l_contour_UIS(expr P)(text txt) =
  T:=identity;
  pickup PenD;
  thdraw P;
  for pnt=txt:
    if pnt=-2:
      mark_(P,arctime(arclength(P)/2) of P, 0.2u);
    elseif pnt>=0:
      mark_(P,pnt,0.2*u);
    fi;
    exitif pnt<0;
  endfor;
enddef;

def l_contour_SKBB(expr P)(text txt) =
  T:=identity;
  pickup PenD;
  thdraw P;
  for pnt=txt:
    if (pnt=-2) or (pnt=-1):
      mark_(P,arctime(arclength(P)/2) of P, 0.2u);
    elseif pnt>=0:
      mark_(P,pnt,0.2*u);
    fi;
    exitif pnt<0;
  endfor;
enddef;

def l_rockborder_UIS (expr P) = 
  T:=identity;
  pickup PenC;
  if cycle P: thclean P fi;
  thdraw P;
enddef;

def l_rockedge_UIS (expr P) = 
  T:=identity;
  pickup PenD;
  thdraw P;
enddef;

def l_border_visible_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path;
enddef;

def l_border_temporary_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path dashed evenly scaled optical_zoom;
enddef;

def l_flowstone_UIS (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .7u);
  if (cycle P) and (dlzka < 3.5u):   % make at least 5 curls on a cyclic path
    mojkrok := dlzka/5;
  fi;
  pickup PenC;  
  t1:=0;
  forever:
    t2 := arctime (cas + mojkrok) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 60)} ..
           {dir (angle(thdir(P,t2)) - 60)}(point t2 of P);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
    t1:=t2;
  endfor;
enddef;


def l_moonmilk_UIS (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .3u);
  pickup PenC;  
  t1:=0;
  forever:
    t2 := arctime (cas + mojkrok) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 80)} ..
           {dir (angle(thdir(P,t2)) - 80)}(point t2 of P);
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
    t1:=t2;
  endfor;
enddef;


def l_survey_surface_SKBB (expr P) =
  T:=identity;
  thdrawoptions(dashed withdots scaled (0.2 * optical_zoom) withpen PenC);
  thdraw P;
  thdrawoptions();
enddef;

def l_survey_cave_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  if ATTR__scrap_centerline:
    thdraw P;
  else:
    PolygonLine:=.8u;
    pair zz[];
    for t = 0 upto length P - 1:
      zz1 := point t of P;
      zz2 := point t+1 of P;
      if length (zz2-zz1) > 2*PolygonLine:
        thdraw zz1 -- zz1 + PolygonLine * unitvector(zz2 - zz1);
        thdraw zz2 -- zz2 + PolygonLine * unitvector(zz1 - zz2);
      else:
        thdraw zz1 -- zz2;
      fi;
    endfor;
  fi;
enddef;

def l_survey_cave_UIS (expr P) =
  T:=identity;
  pair zz[];
  pickup PenC;
  for t = 0 upto length P - 1:
    zz1 := point t of P;
    zz2 := point t+1 of P;
    draw zz1 -- zz2;
  endfor;
enddef;

def l_waterflow_permanent_UIS (expr Path) =
  path ppp;
  T:=identity;
  cas := 0;
  dlzka := arclength Path;
  mojkrok:=adjust_step(dlzka, 0.5u);
    pickup PenD;  
    vardef azim = 50 + 15*normaldeviate enddef;
    az1 := azim;
    sgn := 1;
    ppp := point 0 of Path;
    forever:
        t1 := arctime cas of Path;
        t2 := arctime (cas+mojkrok) of Path;
        if cas+1.1*mojkrok > dlzka:
            az2 := 0;
        else:
            az2 := azim;
        fi;
        d1 := angle(thdir(Path,t1)) + sgn * az1;
        d2 := angle(thdir(Path,t2)) - sgn * az2;
        ppp := ppp & (point t1 of Path){dir d1} .. {dir d2}(point t2 of Path);
        az1 := az2;
        sgn := -1 * sgn;
        cas := cas + mojkrok;
        exitif cas > dlzka + mojkrok/3;     % for rounding errors
    endfor;
%    drawarrow ppp;
    thdraw ppp;
    thdrawoptions();
    oldahlength:=ahlength;
    ahlength:=ahlength*optical_zoom;
    thdraw arrowhead ppp;
    thfill arrowhead ppp;
    ahlength:=oldahlength;
enddef;

def l_waterflow_intermittent_SKBB (expr Path) =
  thdrawoptions(dashed evenly scaled optical_zoom);
  l_waterflow_permanent_UIS (Path);
  thdrawoptions();
enddef;

def l_waterflow_conjectural_SKBB (expr Path) =
  thdrawoptions(dashed withdots scaled (0.5 * optical_zoom) withpen PenB);
  l_waterflow_permanent_UIS (Path);
  thdrawoptions();
enddef;

def l_invisible (expr P) = 
enddef;

def l_undefined (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P withcolor red;
  thwarning("undefined line symbol used");
enddef;

% Q = 0 -- no arrows
%     1 -- end
%     2 -- begin
%     3 -- both

def l_arrow_SKBB (expr P, Q) =
  T:=identity;
  pickup PenC;
  thdraw P;
  p := (-.1u,-.25u)--(0,0)--(.1u,-.25u);
  if odd Q:
    draw p rotated (angle(thdir(P,0))+90) shifted (point 0 of P);
  fi;
  if Q>1:
    draw p rotated (angle(thdir(P,length P))-90) 
         shifted (point infinity of P);
  fi;
enddef;

def l_mapconnection_SKBB (expr P) =
  thdrawoptions(dashed withdots scaled (0.5 * optical_zoom) withpen PenB);
  l_arrow_SKBB(P,3);
  thdrawoptions();
enddef;


def l_section_SKBB (expr P)(text txt) =
  T:=identity;
  path Q; Q = punked P;
  pickup PenC;
  for t = 0 upto length P - 1:
    pair zz[];
    zz1 := point t of P;
    zz2 := point t+1 of P;
    zz3 := postcontrol t of P;
    zz4 := precontrol t+1 of P;
    if (length(zz3-1/3[zz1,zz2]) > 0.1pt) or
       (length(zz4-2/3[zz1,zz2]) > 0.1pt):
      zz5 = whatever[zz1,zz2];
      (zz3-zz5) = whatever * (zz1-zz2) rotated 90;
      draw zz1--zz5;
      zz6 = whatever[zz1,zz2];
      (zz4-zz6) = whatever * (zz1-zz2) rotated 90;
      draw zz2--zz6;
    else:
      draw zz1--zz2;
    fi;
  endfor;
  for pnt=txt:
    if pnt=-1:
    else:
      T:=identity rotated angle(thdir(Q,pnt)) shifted (point pnt of Q);
      pickup PenC;
      thdraw (0,0)--(0,.8u);
      thdraw (-.1u,.55u)--(0,.8u)--(.1u,.55u);
    fi;
    exitif pnt=-1;
  endfor;
enddef;

let l_border_invisible = l_invisible;
let l_wall_invisible = l_invisible;

def l_debug (expr col, pen, P) =
  T:=identity;
  pickup if pen=0: PenD else: PenB fi;
  thdraw P 
    withcolor if col=-2: (1,.85,0)
          elseif col=-1: black 
           elseif col=0: red 
                   else: blue fi;
enddef;


def l_u (expr P) =
  T:=identity;
  pickup PenA;
  thdraw P withcolor red;
enddef;


def l_gradient_UIS (expr P) =
  T:=identity;
  pickup PenC;
  thdraw P;
  p:=(-.15u,-.4u)--(0,0)--(.15u,-.4u)--cycle;
  thfill (p rotated (angle(thdir(P,length P))-90) 
         shifted (point infinity of P));
  thdraw (p rotated (angle(thdir(P,length P))-90) 
         shifted (point infinity of P));
enddef;

def l_gradient_BCRA (expr P) =
  T:=identity;
  pickup PenC;
  for t = 0 upto length P - 1:
    pair zz[];
    zz1 := point t of P;
    zz2 := point t+1 of P;
    zz3 := unitvector(zz2 - zz1);
    thfill zz1 + u/3 * zz3 + .25u * (zz3 rotated 90) --
           zz2 - u/3 * zz3 --
	   zz1 + u/3 * zz3 + .25u * (zz3 rotated -90) -- cycle;
  endfor;
enddef;


def l_rope_SKBB (expr P,exact) =
  T:=identity;
  pickup PenC;
  if exact:
    draw P;
  else:
    d:=0.5u;
    for i:=0 upto (length P - 2):
      x1 := xpart point i of P;
      y1 := ypart point i of P;
      x2 := xpart point i+1 of P;
      y2 := ypart point i+1 of P;
    
      dx1:=x1; dy1:=y1; x1:=0; y1:=0; x2:=x2-dx1; y2:=y2-dy1;
      if y2 > y1:
        y3 := y1 - d;
        x3 := x1 + (x2-x1)*sqrt(d)/(sqrt(d)+sqrt(y2-y1+d));
      else:
        y3 := y2 - d;
        x3 := x1 + (x2-x1)*sqrt(y1-y2+d)/(sqrt(d)+sqrt(y1-y2+d));
      fi;
      numeric a,b,c;
      a*x1/10*x1 + b/10*x1 + c/10 = y1/10;
      a*x2/10*x2 + b/10*x2 + c/10 = y2/10;
      a*x3/10*x3 + b/10*x3 + c/10 = y3/10;
      draw (x1+dx1,y1+dy1)
      for t = x1 step (x2-x1)/20 until x2+10*epsilon:
        -- (t+dx1,a*t*t+b*t+c+dy1)
      endfor;
    endfor;
    pair x;
    x = point (length P)-1 of P + whatewer * down;
    x = point (length P) of P + whatever * right;
    draw point (length P)-1 of P -- x;
%    thdraw point length P of P withpen pencircle scaled 0.3u withcolor red;
  fi;
  for i:=0 upto length P if not exact: -1 fi:
    thdraw point i of P withpen pencircle scaled 0.3u;
  endfor;
enddef;

def l_border_presumed_SKBB (expr Path) =
  T:=identity;
  pickup PenC;
  draw Path dashed evenly scaled (0.25 * optical_zoom);
enddef;

def l_steps_SKBB (expr P) =
 if known ATTR_c: c := scantokens ATTR_c; else: c := 2; fi;
 if ATTR__elevation:
   if (c < 2):
     thwarning("Invalid stairs definition (c<2)");
     pickup PenA;
     draw P withcolor red;
   else:
     path PP;
     if (ypart point 0 of P) < (ypart point length P of P):
       PP := P;
     else:
       PP := reverse P;
     fi;
     path p;     
     for j:=0 upto ((length PP) - 1):
       p := (point j of PP) -- (point (j + 1) of PP);
       c := ceiling(abs((ypart point 0 of p) - (ypart point length p of p)) / (0.2 / Scale * 72 / 2.54));  % 20 cm height
       if (c < 2): c:=2 fi;
       pair cp;
       cp = point length p of p - point 0 of p;
       dx := (xpart cp) / c;
       dy := (ypart cp) / c;
       cp := point 0 of p;
       for i:= 0 upto c - 1:
         l_border_visible(cp -- cp + (0,dy) -- cp + (dx,dy));
         cp := cp + (dx, dy);
       endfor;
       %draw P;
     endfor;
   fi;
 else:
   if known ATTR_l: l := scantokens ATTR_l; else: l := (length(P)-2)/2; fi;
   if ((length(P) < 4) or (c < 2)) or ((odd length P) and (not known ATTR_l)):
     thwarning("Invalid stairs definition" if c<2: &" (c<2)" fi);
     pickup PenA;
     draw P withcolor red;
   else:
     path p, q;
     p = subpath (1, 1+l) of P;
     q = reverse subpath (l+2, length(P)) of P;
     lp := arclength(p);
     lq := arclength(q);
     for i=1 upto c:
       l_border_visible(point(arctime ((i-1)/(c-1)*lp) of p) of p -- point(arctime ((i-1)/(c-1)*lq) of q) of q);
     endfor;
     l_border_visible(p);
     l_border_visible(q);
     drawoptions(withcolor 0.3*white);
     %p_label(decimal c, point 0.5 of P, 0, 6);
     drawoptions();
   fi;
 fi;
enddef;

def l_handrail_SKBB (expr P) = 
    if ATTR__elevation:
      T:=identity;
      cas := 0;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, 1u);
      pickup PenD;  
      pair tmppoint;
      tmph := 1 / Scale * 72 / 2.54;  % 1 m height
      tmppoint:=(point 0 of P) +(0,tmph);
      forever:
        t := arctime cas of P;
        draw point t of P -- (point t of P)+(0,tmph) withpen PenD;
        if cas > 0:
          draw tmppoint -- (point t of P)+(0,tmph) withpen PenC;
          tmppoint := (point t of P)+(0,tmph);
        fi;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
    else:
      T:=identity;
      cas := 0;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, u);
      pickup PenD;  
      forever:
        t := arctime cas of P;
        thdraw point t of P withpen pencircle scaled .25u;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
      pickup PenC;  
      thdraw P;
    fi;
enddef;

def l_fixedladder_SKBB (expr P) = 
  pickup PenD;
  draw P withcolor red;
enddef;

def l_ropeladder_SKBB (expr P) = 
  pickup PenD;
  draw P withcolor red;
enddef;

def l_viaferrata_SKBB (expr P) = 
  pickup PenD;
  draw P withcolor red;
enddef;




%%%%% ENDINPUT thLine %%%%%





%%%%% INPUT thArea %%%%%


%% therion source code
%%
%% This file defines tiling patterns
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thPatterns.mp,v $
%% $Revision: 1.6 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

if unknown a_water_UIS: else: endinput fi;

% patterns

beginpattern(pattern_water_UIS);
    draw origin--10up withpen pensquare scaled (0.02u);
    patternxstep(.18u);
    patterntransform(identity rotated 45);
endpattern;

beginpattern(pattern_sump_UIS);
    draw origin--(0,.25u) withpen pensquare scaled (0.02u);
    draw origin--(.25u,0) withpen pensquare scaled (0.02u);
    patterntransform(identity rotated 45);
endpattern;

beginpattern(pattern_sand_UIS);
    pickup PenC;
    draw (0.2u,.3u);
    draw (0.35u,.7u);
    draw (0.6u,.5u);
    draw (0.8u,.1u);    
endpattern;

beginpattern(pattern_debris_SKBB);
    pickup PenC;
    p:=(-.15u,0)--(.15u,0);
    draw p rotated -40 shifted (.2u,.3u);
    draw p rotated 70 shifted (.9u,1.5u);
    draw p rotated 20 shifted (1.5u,.8u);
%    draw p rotated 95 shifted (.9u,.8u);
endpattern;


beginpattern(pattern_moonmilk_SKBB);
    pickup PenC;
    p:=(-.5u,0){down} .. {up}(-.1666u,0){down}..
        {up}(.1666u,0){down} .. {up}(.5u,0);
    draw p;
    draw p shifted (0.5u,0.3u);
    patternxstep(1.0u);
    patternystep(0.6u);
endpattern;


beginpattern(pattern_flowstone_ASF);
    pickup PenC;
    p:=(-.35u,0){dir -60} .. {dir 60}(0.35u,0);
    draw p;
    draw p shifted (0.35u,0.4u);
    patternxstep(u);
    patternystep(0.8u);
endpattern;


beginpattern(pattern_empty);
  patternbbox(0,0,10,10);
  patternstep(10,10);
endpattern;

% symbols

def a_water_UIS (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_water_UIS;
enddef;

def a_sump_UIS (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_sump_UIS;
enddef;


def a_flowstone_ASF (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_flowstone_ASF;
enddef;


def a_moonmilk_SKBB (expr Path) =
  T:=identity;
  thclean Path;
  thfill Path withpattern pattern_moonmilk_SKBB;
enddef;



def a_sand_UIS (expr p) =
  T:=identity;
%  thclean p;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1u until xpart urcorner q:
      for j = ypart llcorner q step 1u until ypart urcorner q:
        draw origin shifted ((i,j) randomized 0.7u) withpen PenC;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_debris_UIS (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_debris_SKBB;
enddef;


def a_bedrock_SKBB (expr Path) =
  T:=identity;
  thclean Path;
enddef;


% used to export centerline LRUD envelope for maps created from surveys

def a_dimensions_SKBB (expr Path) =
  T:=identity;
  thclean Path;
enddef;


def a_debris_SKBB (expr p) =
  T:=identity;
%  thclean p;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1u until xpart urcorner q:
      for j = ypart llcorner q step 1u until ypart urcorner q:
        draw ((-.2u,0)--(.2u,0)) 
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.6u) withpen PenC;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_clay_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        qq := ((-.25u,0){up}..origin{down}..{up}(0.25u,0)) randomized (u/15)
             shifted ((i,j) randomized 1.3u);
	if xpart (p intersectiontimes qq) < 0:
	  thdraw qq;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_ice_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q; q = bbox p;
  picture tmp_pic, tmp_ice; 
  pair z;
  tmp_ice := image (
    draw (-.2u,0)--(.2u,0);
    draw (0,-.2u)--(0,.2u);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        z := ((i,j) randomized 1.3u);
	if xpart (p intersectiontimes ((bbox tmp_ice) shifted z)) < 0:
	  draw tmp_ice shifted z;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_snow_SKBB (expr P) =
  T:=identity;
  pickup PenC;
  path q; q = bbox P;
  picture tmp_pic, tmp_sn; 
  pair z;
  tmp_sn := image(
    pickup PenC;
    p := origin--(0,.2*u);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240); draw p rotated (300);
    p := ((0,.3u)--(0,0.2u)--(0.1u,0.2u)) rotatedaround ((0,0.2u),45);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240);
    draw p rotated (300);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        z:=((i,j) randomized 1.3u);
	if xpart (P intersectiontimes ((bbox tmp_sn) shifted z)) < 0:
          draw tmp_sn shifted z;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to P;
  drawoptions();
  draw tmp_pic;
enddef;

def a_blocks_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic; 
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart llcorner q)/100);
  tmp_pic := image(
    for i = xpart llcorner q step 2uu until xpart urcorner q:
      for j = ypart llcorner q step 2uu until ypart urcorner q:
        qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle) 
	     randomized (uu/2))
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 1.6uu);
	if xpart (p intersectiontimes qq) < 0:
	  thclean qq;
	  thdraw qq;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_blocks_SKBB_ (expr p,o,s_beg,s_end,d_beg,d_end) =
  T:=identity;
  orient = 90-o;
  pickup PenC;
  path q[], qq; q1 = bbox p;
  draw q1; draw p;
  q2 = llcorner q1 .. lrcorner q1 .. urcorner q1 .. ulcorner q1 .. cycle;
  draw q2;
  pair zz[];
  radius := .5*length(llcorner q1 - urcorner q1);
  zz1 := .5[llcorner q1,urcorner q1];
  zz2 := zz1 - dir(orient)*radius;
  zz3 = zz1 rotatedaround (zz2,90);
  draw zz1 withpen pencircle scaled 2mm;
  draw zz2 withpen pencircle scaled 2mm;
  draw zz3 withpen pencircle scaled 2mm;
  picture tmp_pic; 
  tmp_pic := image(
    j := 0;
    forever:
      i := 0;
      forever:
        qq := punked (((-.5,-.5)--(.5,-.5)--(.5,.5)--(-.5,.5)--cycle) 
             scaled (0.7(5u-(j/(2*radius))[u*s_beg,u*s_end]))
	     randomized (u/2))
             rotated uniformdeviate(360) 
             shifted (((zz3 + (i,j)) rotatedaround (zz3,-o)) randomized 1.6u);
        draw ((zz3 + (i,j)) rotatedaround (zz3,-o)) withpen pencircle scaled 1mm withcolor red;
	if xpart (p intersectiontimes qq) < 0:
	  thclean qq;
	  thdraw qq;
	fi;
        i := i + (j/(2*radius))[u*d_beg,u*d_end];
        exitif i > 2*radius;
      endfor;  
      j := j + (j/(2*radius))[u*d_beg,u*d_end];
      exitif j > 2*radius;
    endfor;
  );
%  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;


def a_pebbles_SKBB (expr p) =
  T:=identity;
  pickup PenC;
  path q, qq; q = bbox p;
  picture tmp_pic; 
  tmp_pic := image(
    for i = xpart llcorner q step 1.5u until xpart urcorner q:
      for j = ypart llcorner q step 1.5u until ypart urcorner q:
        qq := (superellipse((.2u,0),(0,.1u),(-.2u,0),(0,.-.1u),.75))
%             randomized (u/25)
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.8u);
	if xpart (p intersectiontimes qq) < 0:
	  thdraw qq;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;

def a_water_SKBB (expr Path) =
  T:=identity;
  thfill Path;
enddef;

let a_sump_SKBB = a_water_SKBB;

def a_u (expr p) =
    T:=identity;
    thfill p withcolor red;
enddef;




%%%%% ENDINPUT thArea %%%%%





%%%%% INPUT thText %%%%%


%% therion source code
%%
%% This file defines macros for labels
%%
%% $Date: 2003/07/01 09:06:44 $
%% $RCSfile: thText.mp,v $
%% $Revision: 1.6 $
%%
%% Copyright (C) 2000-2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

labeloffset:=0bp;

def l_label(expr txt,path) =
  picture pict,pic;
  pair pos;
  numeric dx[],dy[],ptime;
  string ss,ch;

  pic := thelabel(txt,(0,0));
  strl := xpart(lrcorner pic - llcorner pic);
  pathl := arclength (path);
  dx0 := xpart(llcorner pic);
%  dy0 := ypart(llcorner pic);

  if strl>pathl:
    txtzoom := pathl / strl;
    thwarning("text scaled down to fit the path");
  else:
    txtzoom := 1;
  fi;
  zoom := pathl / strl;

  for p within pic:
    if textual p:                                
      ss := textpart p;
      dx1 := xpart p;
      dy1 := ypart p;
      dx2 := dx1;

      if xxpart p / yypart p <> 1: message("Error: distorted text!") fi;
      txtscale := txtzoom * xxpart p;

      l := length(ss);
      ptime := 0;
      for i=0 upto (l - 1):
        ch := substring(i,i+1) of ss;
        pict := ch infont fontpart p scaled txtscale;
        charwidth := xpart (lrcorner pict - llcorner pict) / txtzoom;
        dy2 := ypart lrcorner pict / txtzoom;
        ptime := (dx2 - dx0 + 0.5*charwidth) * zoom;
        t := arctime ptime of (path);
        pos := point t of path + 
          (dy1+dy2)*txtzoom*unitvector((direction t of path) rotated 90);
        begingroup
%          interim labeloffset:=0bp;
          lab:=thelabel.top(pict,pos);
          process_label(pos,angle direction t of path);
        endgroup;
        dx2 := dx2 + charwidth;
      endfor;

    else: message("Strange component of line label!");
    fi;
  endfor;
  % draw path;
enddef;

vardef p_label@#(expr txt,pos,rot,mode) =
  if (mode=1) or (mode=7): interim labeloffset:=(u/8) fi;
  lab:=thelabel@#(txt, pos);
  if mode>1: pickup PenD fi;
  if mode=1:
    pickup pencircle scaled (u/6);
    drawdot(pos);
    process_label(pos,0);
  elseif mode=2: process_uplabel;       
  elseif mode=3: process_downlabel;
  elseif mode=4: process_updownlabel;
  elseif mode=5: process_circledlabel;
  elseif mode=6: process_boxedlabel;
  elseif mode=7: process_label(pos,rot);  % station name
  elseif mode=8: process_filledlabel(pos, rot);
  else: process_label(pos,rot); fi;
enddef;


% at beginfig: save smartll[], smartur[]; pair smartll[], smartur[]; smart_count=0;
numeric smart_count, smart_D;
boolean smart_quit, smart_inner_quit;

def p_smartlabel (expr txt, pos) =
  begingroup;
  interim bboxmargin:=0.2pt;
  lab:=thelabel.rt(txt,pos+(0.4u,0));
  q:=bbox lab;
  smart_D := 0;
  forever:
    smart_quit := true;
    smart_inner_quit := false;
    for i=1 upto smart_count:
      if smart_overlap(((point 0 of q) shifted (0,smart_D)), 
                       ((point 2 of q) shifted (0,smart_D)),
                       smartll[i], smartur[i]) = 1:
        smart_quit := false;
        smart_D := smart_D - 3pt;
        smart_inner_quit := true;
      fi;
      exitif smart_inner_quit;
    endfor;
    exitif smart_quit;
  endfor;
  smart_U := 0;
  forever:
    smart_quit := true;
    smart_inner_quit := false;
    for i=1 upto smart_count:
      if smart_overlap(((point 0 of q) shifted (0,smart_U)), 
                       ((point 2 of q) shifted (0,smart_U)),
                       smartll[i], smartur[i]) = 1:
        smart_quit := false;
        smart_U := smart_U + 3pt;
        smart_inner_quit := true;
      fi;
      exitif smart_inner_quit;
    endfor;
    exitif smart_quit;
  endfor;
  if (smart_U < -smart_D): smart_D := smart_U; fi;
  draw lab shifted (0,smart_D);
  if (abs(smart_D)>3pt):
    pickup PenB;
    draw pos{left}..{right}(pos shifted (.4u, smart_D)) dashed withdots scaled 0.2;
    pickup PenA;
    drawdot pos;
  fi;
  smart_count := smart_count + 1;
  smartll[smart_count] := point 0 of (q shifted (0,smart_D));
  smartur[smart_count] := point 2 of (q shifted (0,smart_D));
  endgroup;
enddef;

def smart_overlap (expr llA, urA, llB, urB) =
  if ((xpart llA < xpart urB) and (xpart urA > xpart llB)) and
     ((ypart llA < ypart urB) and (ypart urA > ypart llB)):
    1
  else:
    0 
  fi
enddef;




def p_wallaltitude (expr pprev,pos,pnext,txt) =
  rot:=angle(unitvector(pnext-pos)+unitvector(pos-pprev)) - 90;
  pickup PenD;
  pair zz;
%  zz:=(pos + 3*unitvector(dir rot));
  zz:=(pos + (u/4)*unitvector(dir rot));
  draw (pos)--zz;
  begingroup 
%    interim labeloffset:=2pt;
    interim labeloffset:=(u/12);
    if horiz_labels:
      rot:=rot mod 360;
      if rot<=22.5: lab:=thelabel.rt(txt, zz);
      elseif rot<=67.5: lab:=thelabel.urt(txt, zz);
      elseif rot<=112.5: lab:=thelabel.top(txt, zz);
      elseif rot<=157.5: lab:=thelabel.ulft(txt, zz);
      elseif rot<=202.5: lab:=thelabel.lft(txt, zz);
      elseif rot<=247.5: lab:=thelabel.llft(txt, zz);
      elseif rot<=292.5: lab:=thelabel.bot(txt, zz);
      elseif rot<=337.5: lab:=thelabel.lrt(txt, zz);
      else: lab:=thelabel.rt(txt, zz);
      fi;
    else:
      if (abs rot>90) and (abs rot <=270):
        rot:=rot-180;
        lab:=thelabel.lft(txt, pos);
      else:
        lab:=thelabel.rt(txt, pos);
      fi;
    fi;
    process_label(pos, if horiz_labels: 0 else: rot fi);
  endgroup;
enddef;




%%%%% ENDINPUT thText %%%%%





%%%%% INPUT thSpecial %%%%%


%% therion source code
%%
%% This file defines macros for special symbols
%%
%% $Date: $
%% $RCSfile: $
%% $Revision: $
%%
%% Copyright (C) 2004 Martin Budaj
%%
%% -------------------------------------------------------------------- 
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%% --------------------------------------------------------------------

def s_northarrow_SKBB_old (expr rot) = 
  T:=identity;
  picture tmp_pic;
  tmp_pic = image (
    begingroup
      interim defaultscale:=3;
      label(if (lang="sk") or (lang="cz"): "S" else: "N" fi, origin);
    endgroup;
    drawarrow (0,-1cm)--(0,1cm);
  );
  draw tmp_pic rotatedaround(origin, -rot);
enddef;

def s_northarrow_SKBB (expr rot) =
  T:=identity scaled 0.7 rotated -rot;
  thdraw (-.5cm,-1cm)--(0,1.5cm)--(.5cm,-1cm)--(0,-.5cm)--cycle;
  thfill (-.5cm,-1cm)--(0,1.5cm)--(0,-.5cm)--cycle;
enddef;

def s_scalebar_SKBB (expr l, units, txt) = 
  begingroup
    interim warningcheck:=0;
    tmpl:=l / Scale * cm * units / 2;
  endgroup;
  pickup PenC;
  draw (-tmpl,0)--(tmpl,0);
  draw (-tmpl,0)--(-tmpl,2bp);
  draw (tmpl,0)--(tmpl,2bp);
  begingroup
    interim labeloffset:=2bp;
    label.top(thTEX(decimal (l) & "\thinspace" & txt),origin);
  endgroup
enddef;

def s_scalebar_SM (expr l, units, txt) = 
  begingroup
    interim warningcheck:=0;
    tmpl:=l / Scale * cm * units / 2;
  endgroup;
  pickup PenC;
  draw (-tmpl,0)--(tmpl,0);
  draw (-tmpl,0)--(-tmpl,2bp);
  draw (tmpl,0)--(tmpl,2bp);
  draw (0,0)--(0,2bp);
  begingroup
    interim labeloffset:=3.5bp;
    label.top(thTEX(decimal (0)),(-tmpl,0));
    label.top(thTEX(decimal (l/2)),origin);
    label.top(thTEX(decimal (l) & "\thinspace" & txt),(tmpl,0));
  endgroup
enddef;


def s_hgrid_SM (expr xpos, ypos, xsize, ysize) =
  pickup PenD;
  draw (
    if xpos < 0: 0 else: -5mm fi, 0
  ) -- (
    if xpos > 0: 0 else: 5mm fi, 0
  );
  draw (
    0, if ypos < 0: 0 else: -5mm fi
  ) -- (
    0, if ypos > 0: 0 else: 5mm fi
  );
enddef;


def s_vgrid_SM (expr xpos, ypos, xsize, ysize) =
  pickup PenD;
  draw (
    if xpos < 0: 0 else: -xsize/2 fi, 0
  ) -- (
    if xpos > 0: 0 else: xsize/2 fi, 0
  ) dashed evenly;
enddef;




%%%%% ENDINPUT thSpecial %%%%%





%%%%% INPUT uAUT %%%%%


% Austrian Symbol Set, author Georg Pacher

% color (for Austrian symbol-set)

color col_water_bg;
col_water_bg :=(226/255,244/255,253/255);

%%%%%%%%%%%%%%%%%%%%%%%


%% areas

% returns true if pair point lies within path q. 
% outside_point is any pair outside of path q (needed for reference).
vardef pointinside(expr pt,q,outside_point)=
  T:=identity;
  path test;
  test:= outside_point--pt;
  %thdraw test;
  boolean isinside;
  isinside:=false;
  numintersections:=recgetnumintersections(test,q,0);
  if (numintersections <0):
    isinside:=true;
  elseif odd(numintersections):
     isinside:=true;
  else:
     isinside:=false;
  fi;
  isinside
enddef;

% get number of intersection between paths p (length 1!) and q
% recnum is needed for limitation of recursions. 
% If the number of allowed recursions is reached, a negativ number of intersections is returned
vardef recgetnumintersections(expr p,q,recnum)=
  
  pair inter;
  save preinter;
  save postinter;
  save numintersections;
  path preinter, postinter;
  inter:=p intersectiontimes q;
  %show recnum;
  if recnum >25:
    numintersections:=-100;
  else:  
    if xpart(inter)>0 :
     %show (xpart inter);
    % split p into two paths and call yourself again
    
    preinter:=subpath (0,xpart(inter)-2eps) of p;
    
    postinter:=subpath (xpart(inter)+2eps,1) of p;
    
    numintersections:= recgetnumintersections(preinter,q,recnum+1)
                     + recgetnumintersections(postinter,q,recnum+1)
                     + 1;
    else:
      numintersections:=0;
    fi;
  fi;
  numintersections
  
enddef;

beginpattern(pattern_water_AUT);
    draw origin--10up withpen pensquare scaled (0.02u);
    patternxstep(.18u);
    patterntransform(identity rotated 90);
endpattern;

beginpattern(pattern_sump_AUT);
    draw origin--(0,.25u) withpen pensquare scaled (0.02u);
    draw origin--(.25u,0) withpen pensquare scaled (0.02u);
endpattern;

beginpattern(pattern_sand_AUT);
    pickup PenC;
    p:= origin -- (0.01u,0.01u);
    for i=0.0u step 0.2u until 2.4u:
        for j=0.0u step 0.2u until 2.4u:
          draw p rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.09u);
        endfor;
    endfor;
    if BaseScale<=2.5:
      my_step:=2.4u;
    else:
      my_step:=2.6u;
    fi;
    patternstep(my_step,my_step);       
endpattern;

beginpattern(pattern_pebbles_AUT);
    pickup PenC;
    path qq;
    for i=0.0u step 0.3u until 5.1u:
        for j=0.0u step 0.3u until 5.1u:
          qq := (superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75))
             randomized (u/45)
             scaled (uniformdeviate(0.4)+.55)
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.15u);
           draw qq;
        endfor;
    endfor;
    patternstep(5.1u,5.1u);
endpattern;

beginpattern(pattern_ice_AUT);
    pickup PenC;
    p:=(-.15u,.0u) -- (0.15u,.0u);
    draw p;
    draw p shifted (0.25u,.0u) rotated (90);
    draw p shifted (0.45u,0.25u);
    draw p shifted (0.0u,0.45u) rotated (90);
    patternxstep(.9u);
    patternystep(0.5u);
endpattern;

def a_water_AUT (expr Path) =
  T:=identity;
  thclean Path;
  pickup PenC;
  thfill Path withcolor col_water_bg;
  thfill Path withpattern pattern_water_AUT;
  thdraw Path;
enddef;

def a_sump_AUT (expr Path) =
  T:=identity;
  thclean Path;
  pickup PenC;
  thfill Path withcolor col_water_bg;
  thfill Path withpattern pattern_sump_AUT;
  thdraw Path;
enddef;

def a_sand_AUT (expr Path) =
  T:=identity;
%  thclean Path;
  thfill Path withpattern pattern_sand_AUT ;
enddef;

let a_clay_AUT = a_sand_AUT;


def a_pebbles_AUT (expr p) =
  T:=identity;
  thfill p withpattern pattern_pebbles_AUT;
enddef;



def a_debris_AUT (expr p) =
  T:=identity;
  
  symbol_distance:=1.0;
  scale_factor:= 0.3;
  pickup PenC;
  path q, qq; q = bbox p;
  pair outside;
  outside:= ulcorner q + up;
  picture tmp_pic; 
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
  tmp_pic := image(
     for i = xpart llcorner q step symbol_distance*uu until xpart urcorner q:
        for j = ypart llcorner q step symbol_distance*uu until ypart urcorner q:
           qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(1.05uu,0.01uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle) 
           randomized (uu/2))
           scaled (uniformdeviate(0.4)+scale_factor )
           rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.5uu);
           if xpart (p intersectiontimes qq) < 0:
             if pointinside((i,j),p,outside):
               thclean qq;
               thdraw qq;
             fi;
           else:
             qq:= qq scaled (uniformdeviate(.2)+.5 )
             if xpart (p intersectiontimes qq) < 0:
               if pointinside((i,j),p,outside):
                 thclean qq;
                 thdraw qq;
               fi;
             fi;
           fi;
        endfor;  
     endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;  

def a_ice_AUT (expr p) =
  T:=identity;
  thclean p;
  thfill p withpattern pattern_ice_AUT;
  pickup PenC;
  thdraw p;
enddef;

def a_snow_AUT (expr P) =
  T:=identity;
  pickup PenC;
  path q; q = bbox P;
  picture tmp_pic, tmp_sn; 
  pair z;
  tmp_sn := image(
    pickup PenC;
    p := origin--(0,.2*u);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240); draw p rotated (300);
    p := ((0,.3u)--(0,0.2u)--(0.1u,0.2u)) rotatedaround ((0,0.2u),45);
    draw p; draw p rotated (60); draw p rotated (120);
    draw p rotated (180); draw p rotated (240);
    draw p rotated (300);
  );
  tmp_pic := image(
    for i = xpart llcorner q step 1.0u until xpart urcorner q:
      for j = ypart llcorner q step 1.0u until ypart urcorner q:
        z:=((i,j) randomized 0.5u);
	if xpart (P intersectiontimes ((bbox tmp_sn) shifted z)) < 0:
          draw tmp_sn shifted z;
	fi;
      endfor;  
    endfor;
  );
  clip tmp_pic to P;
  draw tmp_pic;
  thdraw P;
enddef;

def a_blocks_AUT (expr p) =
   T:=identity;
  symbol_distance:=1.6;
  scale_factor:= 0.8;
  pickup PenC;
  path q, qq; q = bbox p;
  pair outside;
  outside:= ulcorner q + up;
  picture tmp_pic; 
  uu := max(u, (xpart urcorner q - xpart llcorner q)/100, (ypart urcorner q - ypart     llcorner q)/100);
  tmp_pic := image(
     for i = xpart llcorner q step symbol_distance*uu until xpart urcorner q:
        for j = ypart llcorner q step symbol_distance*uu until ypart urcorner q:
           qq := punked (((-.5uu,-.5uu)--(.5uu,-.5uu)--(1.05uu,0.01uu)--(.5uu,.5uu)--(-.5uu,.5uu)--cycle) 
           randomized (uu/2))
           scaled (uniformdeviate(0.7)+scale_factor )
           rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.75uu);
           if xpart (p intersectiontimes qq) < 0:
             if pointinside((i,j),p,outside):
               thclean qq;
               thdraw qq;
             fi;
           else:
             qq:= qq scaled (uniformdeviate(.2)+.5 )
             if xpart (p intersectiontimes qq) < 0:
               if pointinside((i,j),p,outside):
                 thclean qq;
                 thdraw qq;
               fi;
             fi;
           fi;
        endfor;  
     endfor;
  );
  clip tmp_pic to p;
  drawoptions();
  draw tmp_pic;
enddef;  


%% lines

def l_wall_pit_AUT (expr P) = 
    T:=identity;
    % draw outer path
    pickup PenA;
    thdraw P;

    laenge:= arclength P;

    pair inner[],innerdir[], inter;
    pair test;
    
    samplingdistance:=max(0.15u,laenge/1500);
 
    path testcircle;
    % testcircle, used to test, whether the path makes a 'v'-like bend, 
    % where normal sampling and offsetting gives poor results for the parallel line
    % size of testcircle= size PenA/2 + 2* (distance between outer and inner line)
    % + PenC (inner line)
    testcircle := halfcircle scaled (.5*u/10+2*.125u+.5*u/10) shifted (0,.5*u/10);
    cur:=samplingdistance/2;
    count:=0;
    forever:
      t:= arctime cur of P;
      inter:=P intersectiontimes (testcircle rotated (angle thdir(P,t)) shifted (point t of P));
      
      %thdraw testcircle rotated (angle thdir(P,t)) shifted (point t of P) withpen (pencircle scaled 0.01u) ;
      if (xpart inter) >=0:
        % we are at a 'sharp bend', so set next point to intersectionpoint
        cur:=cur+samplingdistance;
        t := max( xpart inter, arctime cur of P);
        %thdraw point t of P withcolor 0.7*green;
        forever:
          t:= arctime cur of P;
          inter:=P intersectiontimes (testcircle rotated (angle thdir(P,t)) shifted (point t of P));
          exitif (xpart inter <0);
          cur := cur + samplingdistance;
          exitif (cur >=laenge); 
        endfor;
        if (cur <laenge):
          inner[count]:=(point t of P + .125u*unitvector(thdir(P,t) rotated 90) );
          innerdir[count]:=unitvector(thdir(P,t));
          count := count+1;
        fi;
      else:
        inner[count]:= (point t of P + .125u*unitvector(thdir(P,t) rotated 90) );
        innerdir[count]:=unitvector(thdir(P,t));
        %thdraw inner[count] withpen PenD withcolor 0.5*red;
        count:=count +1;
        cur:= cur+ samplingdistance;
      fi;
      exitif (cur >=laenge);
    endfor;
    if count>2:
      % draw inner path
      pickup PenC;
      path innerpath;
      innerpath =
      for i=0 upto count-2:
        inner[i]{(innerdir[i])} ..
      endfor
      if cycle P: cycle;
      else:  inner[count-1];
      fi;
      thdraw innerpath;
        
    % draw the triangles

    path draw_triangle;
    pair l_triangle;
       
    laenge:= arclength innerpath;
    symsize:= adjust_step(laenge,0.5u);
    triangle_width:=symsize/2;
    cur:=(symsize/2);
    t := arctime (cur) of innerpath;
    t1:= arctime (cur-triangle_width/2) of innerpath;
    t2:= arctime (cur+triangle_width/2) of innerpath;         
    l_triangle := (point t of innerpath);
    if ATTR__height >= 10: thfill else: thdraw fi (subpath (t1,t2) of innerpath) -- 
           ((point t of innerpath) + symsize/2 * unitvector(thdir(innerpath,t) rotated 90))
           --  cycle;

    for cur=(symsize/2) step symsize until laenge:
      t := arctime (cur) of innerpath;
      test := (point t of innerpath);
      my_dist := length(test-l_triangle);
      if (abs(my_dist-symsize) < 0.05u) or (my_dist>symsize):
         t1:= arctime (cur-triangle_width/2) of innerpath;
         t2:= arctime (cur+triangle_width/2) of innerpath;         
	 draw_triangle:=(subpath (t1,t2) of innerpath) -- 
                        ((point t of innerpath) + symsize/2 * unitvector(thdir(innerpath,t) rotated 90))
                         --  cycle;
	 if xpart (draw_triangle intersectiontimes P) < 0:
	    if ATTR__height >= 10: 
	      thfill draw_triangle;
	    else:
	      thclean draw_triangle;
	      thdraw draw_triangle;
	    fi;
	    l_triangle:= test;
	 fi;
      fi;
    endfor;
    
    fi;
enddef;


def l_wall_sand_AUT (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, 0.1u);
  pickup PenC;  
  forever:
    t := arctime cas of P;
    thdraw (((0.01u,0.01u)--origin) rotated uniformdeviate(360) shifted ((point t of P) + (uniformdeviate 1) * .4u 
            * unitvector(thdir(P,t) rotated -90)));
    cas := cas + mojkrok;
    exitif cas > dlzka + (mojkrok / 3); % for rounding errors
  endfor;
  pickup PenC;  
  thdraw P;

enddef;

def l_wall_pebbles_AUT (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .18u);
  pickup PenC;
  q:=superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75);
  forever:
    t := arctime (cas + mojkrok/2) of P;
    thdraw q randomized (u/45) rotated (angle(thdir(P,t)) + (normaldeviate*40)) shifted point t of P;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
enddef;


let l_wall_clay_AUT = l_wall_sand_AUT;


def l_wall_debris_AUT (expr P) = 
  T:=identity;
  pickup PenC;
  laenge := arclength P;
  path block;
  path old_block;
  
  cur := 0;
  t:= arctime cur of P;
  % draw first block
  old_block := (((-.0u,-.0u)--(.25u,-.15u)--(.45u,0.01u)--(.2u,.25u)--(.05u,.15u)--cycle));
  block_width := (xpart urcorner old_block - xpart ulcorner old_block);
  old_block:=old_block rotated angle(thdir(P,0)) shifted point t of P;
  thclean old_block;
  thdraw old_block;
   
  cur := cur + 0.9*block_width;
  t:= arctime cur of P;
	% proceed with path
    forever:
	  % generate random block
        block := punked (((-.25u,-.25u)--(0.25.u,-.25u)--(0.50u,0.01u)--(0.25u,.25u)--(-.25u,.25u)--cycle) 
          randomized (u/4))
          scaled (uniformdeviate(0.3)+.4)
          rotated uniformdeviate(360);
	  % check width of block
        block_width := (xpart urcorner block - xpart ulcorner block);
        exitif cur > (laenge- 2.5*block_width/2);
        % find next position where the block fits in without intersecting the previous one
	  forever:           
	    exitif xpart ( (block rotated angle(-direction t of P) shifted point t of P) intersectiontimes old_block) < 0;
            cur:=cur+0.01u;
            t:= arctime cur of P;
            exitif cur > (laenge- 2.5*block_width/2);
          endfor;
        exitif cur > (laenge- 2.5*block_width/2);

        old_block:= block rotated angle(-direction t of P) shifted point t of P;
        thclean old_block;
        thdraw old_block;
        cur := cur + block_width/2;
        t:= arctime cur of P;
    endfor;
	t:= arctime laenge-eps of P;

	% generate last block
      block := (((-.0u,-.0u)--(.25u,-.15u)--(.45u,0.01u)--(.2u,.25u)--(.1u,.15u)--cycle));
     block_width := (xpart urcorner block - xpart ulcorner block);
     
	% scale last block to fit in the remaining gap
     scale_factor:=1.5*(laenge-cur)/block_width;
     forever:
           exitif scale_factor < 0;  % bruces stab at preventing endless loop at large scales
           exitif xpart ( (block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P)) intersectiontimes old_block) < 0;
           scale_factor:=scale_factor-0.01;
     endfor;
     if scale_factor > 0:
       thclean block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P);
       thdraw block rotated angle(-direction t of P) scaled scale_factor shifted (point t of P);
     fi;
enddef;


def l_wall_blocks_AUT (expr P) = 

  T:=identity;
  pickup PenC;
  laenge := arclength P;

  path block;
  path old_block;
  
  cur := 0;
  t:= arctime cur of P;
  
  % draw first block
  old_block := ( (.7u,-.35u)--(.85u,0.01u)--(.4u,.5u)--(.1u,.3u)--(-.0u,-.0u) );
  block_width := (xpart urcorner old_block - xpart ulcorner old_block);
  old_block:=old_block rotated angle( thdir(P,0) ) shifted point t of P;
  thclean (old_block--cycle);
  thdraw old_block;
  
  
  cur := cur + block_width/2;
  t:= arctime cur of P;
  forever:
    % generate random block
    block := punked ( ( (.8u,-.35u)--(.85u,0.01u)--(.6u,.4u)--(.1u,.1u)--(-.0u,-.3u) )
          randomized (0.3u) )
           scaled (uniformdeviate(0.3)+.65)
          rotated (uniformdeviate(45)-15);
    % check width of block
    block_width := (xpart urcorner block - xpart ulcorner block);
    
    exitif cur > (laenge- 3.5*block_width/2);
    % find next position where the block fits in without intersecting the previous one
    forever:    
      exitif xpart ( ((block--cycle) rotated angle(direction t of P) shifted point t of P) intersectiontimes old_block) < 0;
      cur:=cur+0.01u;
      t:= arctime cur of P;
      exitif cur > (laenge- 3.5*block_width/2);
    endfor;
    exitif cur > (laenge- 3.5*block_width/2);
    
    old_block:= block rotated angle(direction t of P) shifted point t of P;
    thclean (old_block--cycle);
    thdraw old_block;
    
    
    cur := cur + block_width/2;
    t:= arctime cur of P;
  endfor;
  
    % generate last block
    t:= arctime laenge-eps of P;
    block := (( (-.15u,-.35u)--(.0u,.0u)--(-.45u,.5u)--(-.75u,.3u)--(-.85u,-.0u)) );
    block_width := (xpart urcorner block - xpart ulcorner block);
    % scale last block to fit in the remaining gap
    scale_factor:=(laenge-cur)/block_width;
    forever:
	  exitif scale_factor < 0;
      exitif xpart ( ( (block) rotated angle (direction t of P) scaled scale_factor shifted (point t of P) ) intersectiontimes old_block) < 0;
      scale_factor:=scale_factor-0.001;
    endfor;
    if scale_factor > 0:
      thclean (block--cycle) rotated angle (direction t of P) scaled scale_factor shifted (point t of P);
      thdraw (block) rotated angle (direction t of P) scaled scale_factor shifted (point t of P);
    fi;
enddef;



def l_wall_ice_AUT (expr P) = 
  T:=identity;
  cas := 0;
  dlzka := arclength P;
  mojkrok:=adjust_step(dlzka, .6u);
  pickup PenC;
  p := (-.15u,0)--(.15u,0);
  q := p rotated 90 shifted (.25u,.0u);
  picture symbol,test_symbol;
  symbol:= image (
             thdraw p;
             thdraw q;
             );
  path bound,old_bound,test_bound;
  begingroup;
    interim bboxmargin:=0;
    bound := bbox (symbol);
  endgroup;
  t := arctime (cas + mojkrok/2) of P;
  thdraw symbol rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
  old_bound:=bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));

  forever:
    t := arctime (cas + mojkrok/2) of P;
    test_bound:= bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
    if xpart ((old_bound) intersectiontimes (test_bound))<0:
      if xpart (P intersectiontimes (test_bound))<0:
        thdraw symbol rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
        old_bound:=bound rotated angle(thdir(P,t)) shifted (point t of P + .25u * unitvector(thdir(P,t) rotated -90));
      fi;
    fi;
    cas := cas + mojkrok;
    exitif cas > dlzka - (2*mojkrok/3); % for rounding errors
  endfor;
  thdraw P;
enddef;


def l_wall_underlying_AUT (expr P) = 
  T:=identity;
  pickup PenA;
  laenge:= arclength P;
  t1 := arctime (0.5u) of P;
  t2 := arctime (laenge-.5u) of P;
  thdraw (subpath (t1,t2) of P) dashed evenly scaled optical_zoom;
enddef;


def l_wall_overlying_AUT (expr P) = 
  T:=identity;
  laenge:= arclength P;
  t1 := arctime (0.25u) of P;
  t2 := arctime (laenge-.25u) of P;
  t3 :=arctime (laenge) of P;
  pickup pensquare scaled (3.5*u/10);
  thdraw (subpath (t1,t2) of P) withcolor background;
    pickup PenA;
  thdraw subpath(0,t1) of P; 
  thdraw subpath(t2,t3) of P;
  thdraw (subpath (t1,t2) of P) dashed dashpattern(on 2bp off 2bp on .5bp off 2bp on 2bp) scaled optical_zoom;
enddef;

def l_wall_moonmilk_AUT (expr P) = 
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.8u);
  circle_width:=symsize/2;
  cur:=(symsize-circle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t2 := arctime (cur + circle_width) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P);
    cur := cur + symsize;
    exitif cur > laenge + (symsize / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_wall_flowstone_AUT (expr P) = 
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.8u);
  circle_width:=symsize/2;
  cur:=(symsize-circle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t2 := arctime (cur + circle_width) of P;
    thdraw (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P);
    thfill (point t1 of P){dir (angle(thdir(P,t1)) + 90)} ..
           {dir (angle(thdir(P,t2)) - 90)}(point t2 of P) --
           (point t1 of P)--cycle;
    cur := cur + symsize;
    exitif cur > laenge + (symsize / 3); % for rounding errors
  endfor;
  pickup PenA;
  thdraw P;
enddef;

def l_pit_AUT (expr P) =
  T:=identity;
  laenge:= arclength P;
  symsize:=adjust_step(laenge,0.5u);
  triangle_width:=symsize/2;
  cur:=(symsize-triangle_width)/2;
  pickup PenC;
  forever:
    t1 := arctime (cur) of P;
    t  := arctime (cur + triangle_width/2) of P;
    t2 := arctime (cur + triangle_width) of P;
    if ATTR__height >= 10:
      thfill (subpath (t1,t2) of P) -- 
        ((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) -- 
        cycle;
    else:
      thclean (subpath (t1,t2) of P) -- 
        ((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) -- 
        cycle;
      thdraw (point t2 of P) --((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) -- 
        (point t1 of P);
    fi;
    cur := cur + symsize;
    exitif cur > laenge - (1*symsize/3); % for rounding errors
    t1:=arctime (cur) of P;
  endfor;
  thdraw P;
enddef;


let l_overhang_AUT = l_pit_AUT;

let l_floorstep_AUT = l_floorstep_UIS;

let l_contour_AUT =l_contour_SKBB;

def l_flowstone_AUT (expr P) = 
  T:=identity;
  pickup PenC;
  thdraw P dashed evenly scaled optical_zoom;
enddef;

def l_survey_cave_AUT (expr P) =
  T:=identity;
  pair zz[];
  pickup PenD;
  thdraw P;
enddef;

%% points

def p_stalactite_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u, .4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,-.4u) -- (0,.15u) -- (-.15u,.4u);
      thdraw (0,.15u) -- (.15u,.4u);
    else:
      U:=(.175u, .175u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thclean fullcircle scaled 0.35u;
      thdraw fullcircle scaled 0.35u;
    fi;
enddef;

let p_icestalactite_AUT = p_stalactite_AUT;

def p_stalagmite_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u,.4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,.4u) -- (0,-.15u) -- (-.15u,-.4u);
      thdraw (0,-.15u) -- (.15u,-.4u);
    else:
      U:=(.15u,.15u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thfill fullcircle scaled 0.3u;
    fi;
enddef;

let p_icestalagmite_AUT = p_stalagmite_AUT;

def p_pillar_AUT(expr pos,theta,sc,al) =
    pickup PenC;
    if ATTR__elevation:
      U:=(.15u,.4u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thdraw (0,.15u)--(0,-.15u);
      thdraw (-.15u,-.4u)--(0,-.15u)--(.15u,-.4u);
      thdraw (-.15u,.4u)--(0,.15u)--(.15u,.4u);
    else:
      U:=(.225u,.225u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      thclean fullcircle scaled 0.45u;
      thdraw fullcircle scaled 0.45u;
      thfill fullcircle scaled 0.3u;
    fi;
enddef;

let p_icepillar_AUT = p_pillar_AUT;

def p_crystal_AUT (expr pos,theta,sc,al)=
    U:=(.35u,.35u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
   
    pickup PenC;
    p := ((-.35*u,0)--(.35*u,0));
    thdraw p;
    thdraw p rotated (45);
    thdraw p rotated (90);
    thdraw p rotated (135);
    
    thdrawoptions();

enddef;

def p_spring_AUT (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,.1u)..(0,-.1u)..(.3u,.1u);
enddef;


def p_sink_AUT (expr pos,theta,sc,al)=
  U:=(.3u,.2u);
  T:=identity aligned al rotated theta scaled sc shifted pos;
  pickup PenC;
  thdraw (-.3u,-.1u)..(0,.1u)..(.3u,-.1u);
enddef;

def p_breakdownchoke_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity rotated -theta aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thclean (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.21u,.305u)--(.0u,-.305u)--(.21u,.305u);
enddef;

def p_sand_AUT (expr pos,theta,sc,al)=
    U:=(.2u,.2u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:= origin -- (0.01u,0.01u);
    for i=-0.1u step 0.2u until .15u:
        for j=-0.1u step 0.2u until .15u:
          thdraw p rotated uniformdeviate(360) 
           shifted ((i,j) randomized 0.09u);
        endfor;
    endfor;
    thdrawoptions();
enddef;

let p_clay_AUT  = p_sand_AUT;

def p_pebbles_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    path qq;
    for i=-0.15u step 0.3u until .2u:
        for j=-0.15u step 0.3u until .2u:
          qq := (superellipse((.1u,0),(0,.05u),(-.1u,0),(0,.-.05u),.75))
             randomized (u/45)
             scaled (uniformdeviate(0.4)+.55)
             rotated uniformdeviate(360) 
             shifted ((i,j) randomized 0.15u);
           thdraw qq;
        endfor;
    endfor;
enddef;

def p_debris_AUT (expr pos,theta,sc,al)=
    U:=(.5u,.5u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    path block,q;
    block :=  ((-.15u,-.15u)--(.15u,-.15u)--(.3u,0.01u)--(.15u,.15u)--(-.15u,.15u)--cycle) ;
    
    q:= (punked (block randomized (0.15u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.3)+0.3) shifted (0.0u,0.15u);
    thclean q; thdraw q;
    
    q:= (punked (block randomized (0.15u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.5)+0.7) shifted (-0.15u,-0.15u);
    thclean q; thdraw q;

    q:=  (punked (block randomized (0.15u))) rotated uniformdeviate(360) shifted (0.15u,-0.15u);
    thclean q; thdraw q;
    
enddef;

def p_blocks_AUT (expr pos,theta,sc,al)=
    U:=(u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;

    path block,q;
    block :=  ((-.25u,-.25u)--(.25u,-.25u)--(.5u,0.01u)--(.25u,.25u)--(-.25u,.25u)--cycle) ;
    
    q:= (punked (block randomized (0.3u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.3)+0.3) shifted (0.0u,0.25u);
    thclean q; thdraw q;
    
    q:= (punked (block randomized (0.3u))) rotated uniformdeviate(360) scaled (uniformdeviate(0.5)+0.7) shifted (-0.25u,-0.25u);
    thclean q; thdraw q;

    q:=  (punked (block randomized (0.3u))) rotated uniformdeviate(360) shifted (0.25u,-0.25u);
    thclean q; thdraw q;
    
enddef;

def p_water_AUT (expr pos,theta,sc,al)=
    U:=(.425u,.3u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenD;
    p:=fullcircle xscaled (.85u) yscaled (.6u);
    thfill p withcolor col_water_bg;
    thfill p withpattern pattern_water_AUT;
    thdraw p;
enddef;

def p_ice_AUT (expr pos,theta,sc,al)=
    U:=(.6u,.4u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:=(-.15u,.0u) -- (0.15u,.0u);
    thdraw p rotated 90;
    thdraw p shifted (0.45u,.0u);
    thdraw p shifted (-0.45u,.0u);
    
    thdraw p rotated 90 shifted (-0.45u,0.25u);
    thdraw p shifted (0u,0.25u);
    thdraw p rotated 90 shifted (0.45u,.25u);
enddef;

def p_entrance_AUT (expr pos,theta,sc,al)=
    U:=(.3u,.75u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    path slice;
    for i= -0.5 step 0.01 until 0.5:
      slice:= (-.3u*(0.5-i),1.5*i*u)--(0,.75u)--(.3u*(0.5-i),1.5i*u)--cycle;
      thfill slice withcolor (min(0.95,0.5-1.75i),min(0.95,.5-1.75i),min(0.95,.5-1.75i));
    endfor;
    thdraw ((-.3u,-0.75u)--(0,.75u)--(.3u,-0.75u)--cycle);
enddef;
    
def p_gradient_AUT (expr pos,theta,sc,al)=
    U:=(.15u,u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thdraw (0,-0.5u)--(0,0.5u);
    p:=(-.15u,.3u)--(0,0.7u)--(.15u,.3u)--cycle;
    thfill p;
    thdraw p;
enddef;

def p_airdraught_AUT (expr pos,theta,sc,al)=
  U:=(.2u,u);
  T:=identity aligned al rotated theta scaled 1 shifted pos;
  pickup PenC;
  thdraw (0,.5u)--(0,-0.8u);
	p:=(-.2u,.2u)--(0,.55u)--(.2u,.2u)--cycle;
	thfill p;
	for i:=1 upto round(3+2*mlog(sc)/mlog 2):
	  thdraw (0,-(1-0.2i)*u)--(.2u,-(1-0.2(i-1))*u);
	  thdraw (0,-(1-0.2i)*u)--(-.2u,-(1-0.2(i-1))*u);
	endfor;
enddef;

def p_station_temporary_AUT (expr pos)=
    T:=identity shifted pos;
    pickup PenD;
    thclean fullcircle scaled 0.15u;
    thdraw fullcircle scaled 0.15u;
enddef;

let p_station_painted_AUT = p_station_temporary_AUT ;
let p_station_fixed_AUT = p_station_temporary_AUT ;

def p_claychoke_AUT (expr pos,theta,sc,al)=
    U:=(.4u,.4u);
    T:=identity rotated -theta aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    thclean (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.4u,-.4u)--(.4u,-.4u)--(.4u,.4u)--(-.4u,.4u)--cycle;
    thdraw (-.15u,.3u)--(-.15u,-.25u)--(.15u,-.25u);
enddef;

def p_claytree_AUT (expr pos,theta,sc,al)=
    U:=(.55u,.6u);
    T:=identity aligned al rotated theta scaled sc shifted pos;
    pickup PenC;
    p:= (-.15u,.15u)--(.0u,.6u)--(.15u,.15u);
    thdraw p ;
    thdraw p shifted (-.4u,-.3u);
    thdraw p shifted (.4u,-.2u) ;
enddef;




%%%%% ENDINPUT uAUT %%%%%






%%%%% INPUT thTrans %%%%%


% default translations

let p_station_fixed = p_station_fixed_ASF;
let p_station_painted = p_station_painted_SKBB;
let p_station_natural = p_station_natural_ASF;              
let p_station_temporary = p_station_temporary_ASF;

let p_waterflow_paleo = p_waterflow_paleo_UIS;
let p_waterflow_permanent = p_waterflow_permanent_UIS;
let p_waterflow_intermittent = p_waterflow_intermittent_UIS;

let p_stalactite = p_stalactite_UIS;
let p_stalagmite = p_stalagmite_UIS;
let p_pillar = p_pillar_UIS;
let p_icestalactite = p_icestalactite_AUT;
let p_icestalagmite = p_icestalagmite_AUT;
let p_icepillar = p_icepillar_AUT;
let p_curtain = p_curtain_UIS;
let p_helictite = p_helictite_UIS;
let p_sodastraw = p_sodastraw_UIS;
let p_crystal = p_crystal_UIS;
let p_flowstone = p_flowstone_UIS;
let p_moonmilk = p_moonmilk_UIS;
let p_wallcalcite = p_wallcalcite_UIS;
let p_popcorn = p_popcorn_UIS;
let p_disk = p_disk_UIS;
let p_gypsum = p_gypsum_NSS;
let p_aragonite = p_aragonite_NSS;
let p_cavepearl = p_cavepearl_SKBB;
let p_gypsumflower = p_gypsumflower_NSS;
let p_rimstonepool = p_rimstonepool_ASF;
let p_rimstonedam = p_rimstonedam_ASF;
let p_anastomosis = p_anastomosis_UIS;
let p_karren = p_karren_UIS;
let p_scallop = p_scallop_UIS;
let p_flute = p_flute_UIS;
let p_raft = p_raft_NSS;
let p_raftcone = p_raftcone_NSS;
let p_spring = p_spring_SKBB;
let p_sink = p_sink_SKBB;
let p_narrowend = p_narrowend_UIS;
let p_lowend = p_lowend_UIS;
let p_flowstonechoke = p_flowstonechoke_NSS;
let p_breakdownchoke = p_breakdownchoke_NSS;
let p_claychoke = p_claychoke_AUT;
let p_claytree = p_claytree_AUT;
let p_bedrock = p_bedrock_ASF;
let p_clay = p_clay_SKBB;                        
let p_sand = p_sand_UIS;
let p_pebbles = p_pebbles_UIS;
let p_debris = p_debris_UIS;
let p_blocks = p_blocks_UIS;
let p_water = p_water_UIS;
let p_ice = p_ice_UIS;
let p_snow = p_snow_SKBB;
let p_archeomaterial = p_archeomaterial_UIS;
let p_paleomaterial = p_paleomaterial_UIS;
let p_guano = p_guano_UIS;
let p_vegetabledebris = p_vegetabledebris_ASF;
let p_root = p_root_ASF;
let p_entrance = p_entrance_UIS;
let p_gradient = p_gradient_UIS;
let p_rope = p_rope_SKBB;          
let p_fixedladder = p_fixedladder_SKBB;   
let p_ropeladder = p_ropeladder_SKBB;    
let p_steps = p_steps_SKBB;         
let p_bridge = p_bridge_SKBB;        
let p_traverse = p_traverse_SKBB;
let p_anchor = p_anchor_SKBB;
let p_camp = p_camp_SKBB;
let p_dig = p_dig_UIS;
let p_noequipment = p_noequipment_SKBB;
let p_sectionarrow = p_sectionarrow_SKBB;
let p_continuation = p_continuation_UIS;
let p_airdraught = p_airdraught_UIS;
let p_airdraught_winter = p_airdraught_winter_UIS;
let p_airdraught_summer = p_airdraught_summer_UIS;
let p_station = p_station_SKBB;
let p_handrail = p_handrail_SKBB;
let p_viaferrata = p_viaferrata_SKBB;
let p_stalactites = p_stalactites_UIS;
let p_stalagmites = p_stalagmites_UIS;
let p_pillars = p_pillars_UIS;

let l_wall_bedrock = l_wall_bedrock_UIS;
let l_wall_sand = l_wall_sand_SKBB;
let l_wall_clay = l_wall_clay_SKBB;
let l_wall_pebbles = l_wall_pebbles_SKBB;
let l_wall_debris = l_wall_debris_SKBB;
let l_wall_blocks = l_wall_blocks_SKBB;
let l_wall_ice = l_wall_ice_SKBB;
let l_wall_underlying = l_wall_underlying_UIS;
let l_wall_unsurveyed = l_wall_unsurveyed_SKBB;
let l_wall_presumed = l_wall_presumed_UIS;
%let l_wall_invisible = l_wall_invisible;
let l_wall_pit = l_wall_pit_AUT;
let l_wall_overlying = l_wall_overlying_AUT;
let l_wall_flowstone = l_wall_flowstone_AUT;
let l_wall_moonmilk = l_wall_moonmilk_AUT;

let l_waterflow_permanent = l_waterflow_permanent_UIS;
let l_waterflow_intermittent = l_waterflow_intermittent_SKBB;
let l_waterflow_conjectural = l_waterflow_conjectural_SKBB;

let l_border_visible = l_border_visible_SKBB;
let l_border_temporary = l_border_temporary_SKBB;
let l_border_presumed = l_border_presumed_SKBB;
%let l_border_invisible = l_border_invisible;

let l_floorstep = l_floorstep_UIS;
let l_pit = l_pit_UIS;
let l_ceilingstep = l_ceilingstep_SKBB;
let l_chimney = l_chimney_UIS;
let l_overhang = l_overhang_SKBB;
let l_slope = l_slope_SKBB;
let l_ceilingmeander = l_ceilingmeander_SKBB;
let l_floormeander = l_floormeander_SKBB;
let l_contour = l_contour_SKBB;
let l_rockborder = l_rockborder_UIS;
let l_rockedge = l_rockedge_UIS;
let l_flowstone = l_flowstone_UIS;
let l_moonmilk = l_moonmilk_UIS;
let l_section = l_section_SKBB;
let l_survey_cave = l_survey_cave_SKBB;
let l_survey_surface = l_survey_surface_SKBB;
let l_arrow = l_arrow_SKBB;
let l_gradient = l_gradient_UIS;
let l_mapconnection = l_mapconnection_SKBB;
let l_handrail = l_handrail_SKBB;
let l_steps = l_steps_SKBB;
let l_fixedladder = l_fixedladder_SKBB;
let l_ropeladder = l_ropeladder_SKBB;
let l_rope = l_rope_SKBB;
let l_viaferrata = l_viaferrata_SKBB;

let a_water = a_water_UIS;
let a_sump = a_sump_UIS;
let a_sand = a_sand_UIS;
let a_debris = a_debris_SKBB;
let a_blocks = a_blocks_SKBB;
let a_snow = a_snow_SKBB;
let a_ice = a_ice_SKBB;
let a_pebbles = a_pebbles_SKBB;
let a_clay = a_clay_SKBB;
let a_bedrock = a_bedrock_SKBB;
let a_flowstone = a_flowstone_ASF;
let a_moonmilk = a_moonmilk_SKBB;
let a_dimensions = a_dimensions_SKBB;

let s_northarrow = s_northarrow_SKBB;
let s_scalebar = s_scalebar_SKBB;
let s_hgrid = s_hgrid_SM;
let s_vgrid = s_vgrid_SM;



%%%%% ENDINPUT thTrans %%%%%



nonstopmode;
initsymbol("s_hgrid_SM");
initsymbol("s_northarrow_SKBB");
initsymbol("s_scalebar_SKBB");
initsymbol("s_scalebar_SM");
initsymbol("s_vgrid_SM");
initsymbol("p_airdraught_AUT");
initsymbol("p_airdraught_UIS");
initsymbol("p_airdraught_summer_UIS");
initsymbol("p_airdraught_winter_UIS");
initsymbol("p_anastomosis_UIS");
initsymbol("p_anchor_SKBB");
initsymbol("p_aragonite_NSS");
initsymbol("p_archeomaterial_UIS");
initsymbol("p_bedrock_ASF");
initsymbol("p_blocks_AUT");
initsymbol("p_blocks_UIS");
initsymbol("p_breakdownchoke_AUT");
initsymbol("p_breakdownchoke_NSS");
initsymbol("p_bridge_SKBB");
initsymbol("p_camp_SKBB");
initsymbol("p_cavepearl_SKBB");
initsymbol("p_clay_AUT");
initsymbol("p_clay_SKBB");
initsymbol("p_claychoke_AUT");
initsymbol("p_claytree_AUT");
initsymbol("p_continuation_UIS");
initsymbol("p_crystal_AUT");
initsymbol("p_crystal_UIS");
initsymbol("p_curtain_UIS");
initsymbol("p_debris_AUT");
initsymbol("p_debris_UIS");
initsymbol("p_dig_UIS");
initsymbol("p_disk_UIS");
initsymbol("p_entrance_AUT");
initsymbol("p_entrance_UIS");
initsymbol("p_fixedladder_SKBB");
initsymbol("p_flowstone_UIS");
initsymbol("p_flowstonechoke_NSS");
initsymbol("p_flute_UIS");
initsymbol("p_gradient_AUT");
initsymbol("p_gradient_BCRA");
initsymbol("p_gradient_NSS");
initsymbol("p_gradient_SKBB");
initsymbol("p_gradient_UIS");
initsymbol("p_guano_UIS");
initsymbol("p_gypsum_NSS");
initsymbol("p_gypsumflower_NSS");
initsymbol("p_handrail_SKBB");
initsymbol("p_helictite_UIS");
initsymbol("p_ice_AUT");
initsymbol("p_ice_UIS");
initsymbol("p_icepillar_AUT");
initsymbol("p_icestalactite_AUT");
initsymbol("p_icestalagmite_AUT");
initsymbol("p_karren_UIS");
initsymbol("p_lowend_NSS");
initsymbol("p_lowend_UIS");
initsymbol("p_moonmilk_UIS");
initsymbol("p_narrowend_UIS");
initsymbol("p_noequipment_SKBB");
initsymbol("p_paleomaterial_UIS");
initsymbol("p_pebbles_AUT");
initsymbol("p_pebbles_UIS");
initsymbol("p_pillar_AUT");
initsymbol("p_pillar_UIS");
initsymbol("p_pillars_UIS");
initsymbol("p_popcorn_UIS");
initsymbol("p_raft_NSS");
initsymbol("p_raftcone_NSS");
initsymbol("p_rimstonedam_ASF");
initsymbol("p_rimstonepool_ASF");
initsymbol("p_root_ASF");
initsymbol("p_rope_SKBB");
initsymbol("p_ropeladder_SKBB");
initsymbol("p_sand_AUT");
initsymbol("p_sand_UIS");
initsymbol("p_scallop_UIS");
initsymbol("p_sink_AUT");
initsymbol("p_sink_SKBB");
initsymbol("p_snow_SKBB");
initsymbol("p_sodastraw_UIS");
initsymbol("p_spring_AUT");
initsymbol("p_spring_SKBB");
initsymbol("p_stalactite_AUT");
initsymbol("p_stalactite_UIS");
initsymbol("p_stalactites_UIS");
initsymbol("p_stalagmite_AUT");
initsymbol("p_stalagmite_UIS");
initsymbol("p_stalagmites_UIS");
initsymbol("p_station_SKBB");
initsymbol("p_station_fixed_ASF");
initsymbol("p_station_fixed_AUT");
initsymbol("p_station_natural_ASF");
initsymbol("p_station_painted_AUT");
initsymbol("p_station_painted_SKBB");
initsymbol("p_station_temporary_ASF");
initsymbol("p_station_temporary_AUT");
initsymbol("p_station_temporary_SKBB");
initsymbol("p_steps_SKBB");
initsymbol("p_traverse_SKBB");
initsymbol("p_vegetabledebris_ASF");
initsymbol("p_viaferrata_SKBB");
initsymbol("p_wallcalcite_UIS");
initsymbol("p_water_AUT");
initsymbol("p_water_UIS");
initsymbol("p_waterflow_intermittent_UIS");
initsymbol("p_waterflow_paleo_UIS");
initsymbol("p_waterflow_permanent_UIS");
initsymbol("l_arrow_SKBB");
initsymbol("l_border_presumed_SKBB");
initsymbol("l_border_temporary_SKBB");
initsymbol("l_border_visible_SKBB");
initsymbol("l_ceilingmeander_NZSS");
initsymbol("l_ceilingmeander_SKBB");
initsymbol("l_ceilingmeander_UIS");
initsymbol("l_ceilingstep_NZSS");
initsymbol("l_ceilingstep_SKBB");
initsymbol("l_ceilingstep_UIS");
initsymbol("l_chimney_NZSS");
initsymbol("l_chimney_UIS");
initsymbol("l_contour_AUT");
initsymbol("l_contour_SKBB");
initsymbol("l_contour_UIS");
initsymbol("l_fixedladder_SKBB");
initsymbol("l_floormeander_SKBB");
initsymbol("l_floorstep_AUT");
initsymbol("l_floorstep_UIS");
initsymbol("l_flowstone_AUT");
initsymbol("l_flowstone_UIS");
initsymbol("l_gradient_BCRA");
initsymbol("l_gradient_UIS");
initsymbol("l_handrail_SKBB");
initsymbol("l_mapconnection_SKBB");
initsymbol("l_moonmilk_UIS");
initsymbol("l_overhang_AUT");
initsymbol("l_overhang_SKBB");
initsymbol("l_pit_AUT");
initsymbol("l_pit_UIS");
initsymbol("l_rockborder_UIS");
initsymbol("l_rockedge_UIS");
initsymbol("l_rope_SKBB");
initsymbol("l_ropeladder_SKBB");
initsymbol("l_section_SKBB");
initsymbol("l_slope_BCRA");
initsymbol("l_slope_SKBB");
initsymbol("l_steps_SKBB");
initsymbol("l_survey_cave_AUT");
initsymbol("l_survey_cave_SKBB");
initsymbol("l_survey_cave_UIS");
initsymbol("l_survey_surface_SKBB");
initsymbol("l_viaferrata_SKBB");
initsymbol("l_wall_bedrock_UIS");
initsymbol("l_wall_blocks_AUT");
initsymbol("l_wall_blocks_SKBB");
initsymbol("l_wall_clay_AUT");
initsymbol("l_wall_clay_SKBB");
initsymbol("l_wall_debris_AUT");
initsymbol("l_wall_debris_SKBB");
initsymbol("l_wall_flowstone_AUT");
initsymbol("l_wall_ice_AUT");
initsymbol("l_wall_ice_SKBB");
initsymbol("l_wall_moonmilk_AUT");
initsymbol("l_wall_overlying_AUT");
initsymbol("l_wall_pebbles_AUT");
initsymbol("l_wall_pebbles_SKBB");
initsymbol("l_wall_pit_AUT");
initsymbol("l_wall_presumed_NZSS");
initsymbol("l_wall_presumed_UIS");
initsymbol("l_wall_sand_AUT");
initsymbol("l_wall_sand_SKBB");
initsymbol("l_wall_underlying_AUT");
initsymbol("l_wall_underlying_UIS");
initsymbol("l_wall_unsurveyed_SKBB");
initsymbol("l_waterflow_conjectural_SKBB");
initsymbol("l_waterflow_intermittent_SKBB");
initsymbol("l_waterflow_permanent_UIS");
initsymbol("a_bedrock_SKBB");
initsymbol("a_blocks_AUT");
initsymbol("a_blocks_SKBB");
initsymbol("a_clay_AUT");
initsymbol("a_clay_SKBB");
initsymbol("a_debris_AUT");
initsymbol("a_debris_SKBB");
initsymbol("a_debris_UIS");
initsymbol("a_dimensions_SKBB");
initsymbol("a_flowstone_ASF");
initsymbol("a_ice_AUT");
initsymbol("a_ice_SKBB");
initsymbol("a_moonmilk_SKBB");
initsymbol("a_pebbles_AUT");
initsymbol("a_pebbles_SKBB");
initsymbol("a_sand_AUT");
initsymbol("a_sand_UIS");
initsymbol("a_snow_AUT");
initsymbol("a_snow_SKBB");
initsymbol("a_sump_AUT");
initsymbol("a_sump_SKBB");
initsymbol("a_sump_UIS");
initsymbol("a_water_AUT");
initsymbol("a_water_SKBB");
initsymbol("a_water_UIS");

lang:="fr";
ATTR__elevation:=false;

% user defined symbols defaults
% end of user defined symbols

defaultfont:="cmss10";
NorthDir:="grid";
fonts_setup(6,8,14,18,28);
transparency:=true;
background:=(1.00000,0.53500,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.53500, 0.25000);
current_scrap := "entree-60SP6@entree-60.D35projet";
ATTR__scrap := "entree-60SP6";
beginfig(1);
ATTR__survey := "entree-60.D35projet";
ATTR__height := -1;
drawoptions();
l_floormeander(((5.25,3.89)
 .. controls (5.25,3.89) and (5.33,5.75) .. (5.55,6.27)
 .. controls (5.77,6.80) and (5.70,7.44) .. (5.89,7.67)
));
endfig;
beginfig(2);
draw_upscrap(1)(1,((4.58,7.94)
 .. controls (4.59,7.41) and (4.24,5.78) .. (4.07,5.48)
 .. controls (3.90,5.20) and (3.96,3.81) .. (4.07,2.71)
 .. controls (4.17,1.61) and (3.95,1.55) .. (4.17,0.24)
 .. controls (4.39,-1.07) and (5.13,-1.18) .. (5.29,-2.06)
 .. controls (5.45,-2.95) and (5.68,-4.62) .. (5.70,-5.28)
 .. controls (5.73,-5.93) and (6.04,-7.94) .. (6.04,-7.94)
),
1,((8.18,-7.33)
 .. controls (8.18,-7.33) and (7.86,-5.08) .. (7.86,-4.49)
 .. controls (7.86,-3.90) and (7.54,-3.47) .. (7.54,-4.08)
 .. controls (7.55,-4.69) and (7.42,-2.45) .. (7.42,-2.29)
 .. controls (7.42,-2.13) and (8.00,-1.38) .. (8.08,-0.06)
 .. controls (8.16,1.25) and (8.52,3.30) .. (8.41,3.98)
 .. controls (8.31,4.67) and (8.37,5.51) .. (8.38,6.12)
 .. controls (8.39,6.73) and (8.46,7.36) .. (8.46,7.36)
));
draw_downscrap;
endfig;
beginfig(3);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((8.18,-7.33)
 .. controls (8.18,-7.33) and (7.86,-5.08) .. (7.86,-4.49)
 .. controls (7.86,-3.90) and (7.54,-3.47) .. (7.54,-4.08)
 .. controls (7.55,-4.69) and (7.42,-2.45) .. (7.42,-2.29)
 .. controls (7.42,-2.13) and (8.00,-1.38) .. (8.08,-0.06)
 .. controls (8.16,1.25) and (8.52,3.30) .. (8.41,3.98)
 .. controls (8.31,4.67) and (8.37,5.51) .. (8.38,6.12)
 .. controls (8.39,6.73) and (8.46,7.36) .. (8.46,7.36)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((4.87,-4.58)
 -- (-7.12,-4.56)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.58,7.94)
 .. controls (4.59,7.41) and (4.24,5.78) .. (4.07,5.48)
 .. controls (3.90,5.20) and (3.96,3.81) .. (4.07,2.71)
 .. controls (4.17,1.61) and (3.95,1.55) .. (4.17,0.24)
 .. controls (4.39,-1.07) and (5.13,-1.18) .. (5.29,-2.06)
 .. controls (5.45,-2.95) and (5.68,-4.62) .. (5.70,-5.28)
 .. controls (5.73,-5.93) and (6.04,-7.94) .. (6.04,-7.94)
));
endfig;
beginfig(4);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char82 \char51 \mainfont{} etex,(-8.52,-4.56),0.0,0);
endfig;
background:=(1.00000,0.49000,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.49000, 0.25000);
current_scrap := "entree-60SP5@entree-60.D35projet";
ATTR__scrap := "entree-60SP5";
beginfig(5);
draw_upscrap(1)(1,((-0.31,-0.08)
 .. controls (-0.31,-0.08) and (0.20,-4.89) .. (0.47,-5.43)
 .. controls (0.74,-5.97) and (2.18,-8.52) .. (3.64,-4.20)
 .. controls (5.11,0.12) and (4.57,-0.21) .. (4.90,1.74)
 .. controls (5.24,3.70) and (5.49,6.81) .. (5.33,7.84)
 .. controls (5.18,8.88) and (5.54,11.96) .. (5.65,13.47)
 .. controls (5.76,14.97) and (5.78,18.28) .. (5.42,19.67)
 .. controls (5.06,21.07) and (4.39,29.44) .. (4.41,30.11)
),
1,((2.50,30.25)
 .. controls (2.50,30.25) and (2.43,29.60) .. (2.41,28.92)
 .. controls (2.39,28.25) and (2.48,27.41) .. (2.54,26.63)
 .. controls (2.61,25.84) and (2.18,24.15) .. (2.25,23.34)
 .. controls (2.32,22.53) and (2.50,20.33) .. (2.61,19.88)
 .. controls (2.72,19.43) and (3.22,18.32) .. (3.29,17.92)
 .. controls (3.35,17.51) and (3.11,9.21) .. (3.24,8.67)
 .. controls (3.38,8.13) and (3.29,6.83) .. (3.22,6.15)
 .. controls (3.15,5.48) and (2.63,2.04) .. (2.66,1.23)
 .. controls (2.68,0.42) and (2.56,-1.27) .. (2.38,-0.91)
 .. controls (2.20,-0.55) and (1.80,0.10) .. (1.82,0.53)
));
draw_downscrap;
endfig;
beginfig(6);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2.50,30.25)
 .. controls (2.50,30.25) and (2.43,29.60) .. (2.41,28.92)
 .. controls (2.39,28.25) and (2.48,27.41) .. (2.54,26.63)
 .. controls (2.61,25.84) and (2.18,24.15) .. (2.25,23.34)
 .. controls (2.32,22.53) and (2.50,20.33) .. (2.61,19.88)
 .. controls (2.72,19.43) and (3.22,18.32) .. (3.29,17.92)
 .. controls (3.35,17.51) and (3.11,9.21) .. (3.24,8.67)
 .. controls (3.38,8.13) and (3.29,6.83) .. (3.22,6.15)
 .. controls (3.15,5.48) and (2.63,2.04) .. (2.66,1.23)
 .. controls (2.68,0.42) and (2.56,-1.27) .. (2.38,-0.91)
 .. controls (2.20,-0.55) and (1.80,0.10) .. (1.82,0.53)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-0.31,-0.08)
 .. controls (-0.31,-0.08) and (0.20,-4.89) .. (0.47,-5.43)
 .. controls (0.74,-5.97) and (2.18,-8.52) .. (3.64,-4.20)
 .. controls (5.11,0.12) and (4.57,-0.21) .. (4.90,1.74)
 .. controls (5.24,3.70) and (5.49,6.81) .. (5.33,7.84)
 .. controls (5.18,8.88) and (5.54,11.96) .. (5.65,13.47)
 .. controls (5.76,14.97) and (5.78,18.28) .. (5.42,19.67)
 .. controls (5.06,21.07) and (4.39,29.44) .. (4.41,30.11)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((4.66,-3.34)
 -- (4.66,-18.37)
 -- (-4.25,-28.81)
));
drawoptions();
p_dig((-0.05,-8.09),0.0,1.00,(-1,-1));
endfig;
beginfig(7);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char66 \char111 \char121 \char97 \char117 \ \char49 \char50 \char109 \char58 \ \char54 \ \char115 \thfc\char233 \thfb\char97 \char110 \char99 \char101 \char115 \mainfont{} etex,(-5.78,-30.25),0.0,0);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char51 \char56 \char56 \mainfont{} etex,(-0.11,-1.70),0.0,1);
endfig;
background:=(1.00000,0.45250,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.45250, 0.25000);
current_scrap := "entree-60SP4@entree-60.D35projet";
ATTR__scrap := "entree-60SP4";
beginfig(8);
ATTR__height := -1;
drawoptions();
l_pit(((-9.57,-7.14)
 .. controls (-9.26,-7.05) and (-8.00,-7.23) .. (-8.00,-7.23)
));
ATTR__height := -1;
drawoptions();
l_pit(((-8.00,-7.23)
 .. controls (-7.84,-7.23) and (-6.96,-6.74) .. (-6.40,-5.68)
));
ATTR__height := -1;
drawoptions();
l_pit(((-6.40,-5.68)
 .. controls (-6.40,-5.68) and (-6.24,-4.94) .. (-6.19,-4.58)
 .. controls (-6.16,-4.29) and (-6.62,-2.06) .. (-7.41,-1.13)
 .. controls (-8.04,-0.39) and (-9.27,0.14) .. (-10.04,0.74)
 .. controls (-10.33,0.96) and (-10.47,0.79) .. (-10.72,0.31)
 .. controls (-11.05,-0.34) and (-11.53,-2.92) .. (-11.82,-4.26)
 .. controls (-12.11,-5.61) and (-11.64,-6.29) .. (-11.12,-6.78)
));
endfig;
beginfig(9);
draw_upscrap(1)(1,((-6.20,-7.34)
 .. controls (-6.42,-6.98) and (-5.93,-7.64) .. (-6.42,-7.01)
 .. controls (-6.92,-6.38) and (-6.06,-6.72) .. (-5.81,-5.39)
 .. controls (-4.82,0.01) and (-9.28,0.65) .. (-9.95,1.39)
 .. controls (-10.90,2.44) and (-10.90,1.37) .. (-11.48,0.11)
 .. controls (-12.01,-1.05) and (-11.76,-1.35) .. (-12.34,-3.79)
 .. controls (-12.90,-6.15) and (-11.39,-7.59) .. (-11.39,-7.59)
),
1,((-11.39,-7.59)
 .. controls (-11.39,-7.59) and (-11.12,-8.02) .. (-11.30,-8.78)
 .. controls (-11.48,-9.55) and (-11.33,-9.86) .. (-11.33,-10.40)
),
1,reverse ((-9.30,-7.68)
 .. controls (-9.30,-7.68) and (-9.50,-9.73) .. (-9.41,-10.54)
),
1,((-9.30,-7.68)
 .. controls (-8.51,-7.55) and (-8.15,-7.48) .. (-7.97,-7.61)
 .. controls (-7.79,-7.75) and (-8.13,-7.41) .. (-7.82,-7.86)
));
draw_downscrap;
endfig;
beginfig(10);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.39,-7.59)
 .. controls (-11.39,-7.59) and (-11.12,-8.02) .. (-11.30,-8.78)
 .. controls (-11.48,-9.55) and (-11.33,-9.86) .. (-11.33,-10.40)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-6.20,-7.34)
 .. controls (-6.42,-6.98) and (-5.93,-7.64) .. (-6.42,-7.01)
 .. controls (-6.92,-6.38) and (-6.06,-6.72) .. (-5.81,-5.39)
 .. controls (-4.82,0.01) and (-9.28,0.65) .. (-9.95,1.39)
 .. controls (-10.90,2.44) and (-10.90,1.37) .. (-11.48,0.11)
 .. controls (-12.01,-1.05) and (-11.76,-1.35) .. (-12.34,-3.79)
 .. controls (-12.90,-6.15) and (-11.39,-7.59) .. (-11.39,-7.59)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-6.62,0.11)
 -- (2.45,0.10)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((2.45,0.10)
 -- (12.23,9.77)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.30,-7.68)
 .. controls (-8.51,-7.55) and (-8.15,-7.48) .. (-7.97,-7.61)
 .. controls (-7.79,-7.75) and (-8.13,-7.41) .. (-7.82,-7.86)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.30,-7.68)
 .. controls (-9.30,-7.68) and (-9.50,-9.73) .. (-9.41,-10.54)
));
endfig;
beginfig(11);
drawoptions();
p_label.top(btex \thaltitude \thfb\char49 \char51 \char57 \char56 \mainfont{} etex,(-10.60,1.86),0.0,1);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \ \char100 \char101 \ \char108 \char39 \char79 \char101 \char105 \char108 \ \char83 \char97 \char110 \char103 \char117 \char105 \char110 \char111 \char108 \char97 \char110 \char116 \char58 \ \char80 \char49 \char52 \mainfont{} etex,(12.90,10.54),0.0,0);
endfig;
background:=(1.00000,0.36250,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.36250, 0.25000);
current_scrap := "entree-60SP3@entree-60.D35projet";
ATTR__scrap := "entree-60SP3";
beginfig(12);
ATTR__height := -1;
drawoptions();
l_pit(((-6.68,1.30)
 .. controls (-6.93,0.92) and (-7.67,0.27) .. (-7.92,-0.05)
 .. controls (-8.17,-0.36) and (-9.86,-1.98) .. (-9.34,-2.81)
 .. controls (-8.82,-3.65) and (-8.78,-4.59) .. (-7.36,-5.15)
 .. controls (-6.62,-5.45) and (-6.08,-5.49) .. (-4.77,-4.70)
));
ATTR__height := -1;
drawoptions();
l_pit(((-4.77,-4.70)
 .. controls (-3.46,-3.92) and (-3.71,-3.74) .. (-3.58,-2.99)
 .. controls (-3.44,-2.25) and (-2.79,2.27) .. (-4.28,2.23)
));
endfig;
beginfig(13);
draw_upscrap(1)(1,((-6.62,1.91)
 .. controls (-6.82,1.19) and (-12.87,-2.09) .. (-7.97,-5.47)
 .. controls (-6.51,-6.47) and (-5.94,-5.47) .. (-5.00,-5.20)
),
1,((-5.00,-5.20)
 .. controls (-5.00,-5.20) and (-3.65,-7.76) .. (-2.07,-7.85)
),
1,((-0.99,-4.25)
 .. controls (-2.25,-3.94) and (-2.97,-3.80) .. (-3.10,-3.31)
),
1,((-3.10,-3.31)
 .. controls (-3.10,-3.31) and (-1.62,2.95) .. (-4.55,2.81)
),
1,((-4.55,2.81)
 .. controls (-4.80,3.15) and (-5.81,4.32) .. (-6.03,4.68)
),
1,((-7.65,4.16)
 .. controls (-7.34,3.71) and (-6.50,2.44) .. (-6.62,1.91)
));
draw_downscrap;
endfig;
beginfig(14);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.65,4.16)
 .. controls (-7.34,3.71) and (-6.50,2.44) .. (-6.62,1.91)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.55,2.81)
 .. controls (-4.80,3.15) and (-5.81,4.32) .. (-6.03,4.68)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.10,-3.31)
 .. controls (-3.10,-3.31) and (-1.62,2.95) .. (-4.55,2.81)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-2.21,-0.43)
 -- (4.55,-0.43)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((4.55,-0.43)
 -- (11.84,6.86)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-6.62,1.91)
 .. controls (-6.82,1.19) and (-12.87,-2.09) .. (-7.97,-5.47)
 .. controls (-6.51,-6.47) and (-5.94,-5.47) .. (-5.00,-5.20)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-0.99,-4.25)
 .. controls (-2.25,-3.94) and (-2.97,-3.80) .. (-3.10,-3.31)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.00,-5.20)
 .. controls (-5.00,-5.20) and (-3.65,-7.76) .. (-2.07,-7.85)
));
drawoptions();
p_dig((-2.88,5.35),0.0,1.00,(1,1));
endfig;
beginfig(15);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char100 \char117 \ \char80 \char97 \char112 \char105 \char108 \char108 \char111 \char110 \ \char90 \char111 \char109 \char98 \char105 \char58 \ \char80 \char56 \mainfont{} etex,(12.87,7.85),0.0,0);
endfig;
background:=(1.00000,0.30250,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.30250, 0.25000);
current_scrap := "entree-60SP2@entree-60.D35projet";
ATTR__scrap := "entree-60SP2";
beginfig(16);
ATTR__height := -1;
drawoptions();
l_border_visible(((-7.90,15.98)
 .. controls (-7.90,15.98) and (-2.18,11.95) .. (-6.39,8.12)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-14.18,15.82)
 .. controls (-14.18,15.82) and (-11.23,11.75) .. (-14.67,8.06)
));
endfig;
beginfig(17);
draw_upscrap(1)(1,((-16.61,9.56)
 .. controls (-15.03,9.47) and (-15.21,10.24) .. (-13.37,9.74)
 .. controls (-11.52,9.25) and (-11.43,9.47) .. (-10.49,9.34)
 .. controls (-9.54,9.20) and (-4.28,8.89) .. (-2.39,8.44)
),
1,((1.39,12.44)
 .. controls (1.17,12.71) and (0.83,12.78) .. (1.24,13.37)
 .. controls (1.64,13.95) and (2.32,14.29) .. (3.04,14.51)
 .. controls (3.76,14.74) and (5.51,16.56) .. (5.51,16.56)
),
1,((4.79,17.44)
 .. controls (4.16,17.21) and (1.71,16.97) .. (1.08,16.74)
 .. controls (0.45,16.52) and (-1.10,15.93) .. (-1.82,15.26)
 .. controls (-2.54,14.58) and (-2.67,14.64) .. (-3.47,14.06)
),
1,((-3.47,14.06)
 .. controls (-4.43,13.73) and (-12.87,14.56) .. (-13.73,13.79)
),
1,((-13.73,13.79)
 .. controls (-13.73,13.79) and (-14.27,12.85) .. (-15.53,13.16)
));
draw_downscrap;
endfig;
beginfig(18);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.47,14.06)
 .. controls (-4.43,13.73) and (-12.87,14.56) .. (-13.73,13.79)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-13.21,-0.81)
 -- (2.34,-16.40)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-13.21,8.78)
 -- (-13.21,-0.81)
));
drawoptions();
p_gradient((-13.79,11.66),89.2,0.71,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.79,17.44)
 .. controls (4.16,17.21) and (1.71,16.97) .. (1.08,16.74)
 .. controls (0.45,16.52) and (-1.10,15.93) .. (-1.82,15.26)
 .. controls (-2.54,14.58) and (-2.67,14.64) .. (-3.47,14.06)
));
drawoptions();
p_dig((-9.50,5.99),0.0,1.00,(0,-1));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1.39,12.44)
 .. controls (1.17,12.71) and (0.83,12.78) .. (1.24,13.37)
 .. controls (1.64,13.95) and (2.32,14.29) .. (3.04,14.51)
 .. controls (3.76,14.74) and (5.51,16.56) .. (5.51,16.56)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((5.74,17.42)
 -- (15.44,17.42)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-13.73,13.79)
 .. controls (-13.73,13.79) and (-14.27,12.85) .. (-15.53,13.16)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-16.61,9.56)
 .. controls (-15.03,9.47) and (-15.21,10.24) .. (-13.37,9.74)
 .. controls (-11.52,9.25) and (-11.43,9.47) .. (-10.49,9.34)
 .. controls (-9.54,9.20) and (-4.28,8.89) .. (-2.39,8.44)
));
endfig;
beginfig(19);
drawoptions();
p_label.lrt(btex \thlabel\thnormalsize \thfb\char82 \char52 \char58 \ \char49 \char52 \ \char115 \thfc\char233 \thfb\char97 \char110 \char99 \char101 \char115 \mainfont{} etex,(3.42,-17.46),0.0,0);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char105 \char109 \char112 \mainfont{} etex,(16.61,17.46),0.0,0);
endfig;
background:=(1.00000,0.25000,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.25000, 0.25000);
current_scrap := "entree-60SP1@entree-60.D35projet";
ATTR__scrap := "entree-60SP1";
beginfig(20);
ATTR__height := -1;
drawoptions();
l_floorstep(((-11.68,4.16)
 .. controls (-12.78,4.66) and (-13.77,1.58) .. (-12.17,1.08)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-22.23,3.10)
 .. controls (-17.39,4.09) and (-18.16,9.02) .. (-18.16,9.02)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((-12.17,1.08)
 .. controls (-10.80,0.59) and (-9.97,3.60) .. (-11.68,4.16)
));
endfig;
beginfig(21);
draw_upscrap(1)(1,((-23.42,4.77)
 .. controls (-21.53,4.32) and (-14.02,1.53) .. (-12.17,1.08)
),
0,((-12.17,1.08)
 .. controls (-10.73,0.69) and (-9.99,3.58) .. (-11.68,4.16)
),
1,((-11.68,4.16)
 .. controls (-11.68,4.16) and (-14.29,5.99) .. (-16.49,6.66)
 .. controls (-18.70,7.33) and (-16.81,7.20) .. (-19.64,8.77)
));
draw_downscrap;
endfig;
beginfig(22);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-23.42,4.77)
 .. controls (-21.53,4.32) and (-14.02,1.53) .. (-12.17,1.08)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.68,4.16)
 .. controls (-11.68,4.16) and (-14.29,5.99) .. (-16.49,6.66)
 .. controls (-18.70,7.33) and (-16.81,7.20) .. (-19.64,8.77)
));
drawoptions();
p_gradient((-18.49,5.26),63.2,0.71,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((-15.32,1.40)
 -- (-15.32,-6.08)
));
drawoptions();
p_airdraught_summer((-6.14,10.28),238.7,1.00,(0,0));
drawoptions();
p_airdraught_winter((-8.10,6.12),54.2,1.00,(0,0));
drawoptions();
p_entrance((2.32,-2.63),70.8,2.00,(0,0));
endfig;
beginfig(23);
drawoptions();
p_label.lrt(btex \thaltitude \thfb\char49 \char52 \char50 \char53 \mainfont{} etex,(-11.68,1.01),0.0,1);
drawoptions();
p_label.bot(btex \thlabel\thnormalsize \thfb\char82 \char50 \mainfont{} etex,(-15.30,-7.29),0.0,0);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char69 \char110 \char116 \char114 \thfc\char233 \thfb\char101 \ \char68 \char51 \char53 \mainfont{} etex,(23.42,-10.28),0.0,0);
endfig;
background:=(1.00000,0.82000,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.82000, 0.25000);
current_scrap := "50a-85SP6@50a-85.D35projet";
ATTR__scrap := "50a-85SP6";
beginfig(24);
draw_upscrap(1)(1,((-6.01,-6.85)
 .. controls (-6.01,-6.85) and (-5.48,-7.66) .. (-5.85,-8.06)
 .. controls (-6.21,-8.47) and (-6.65,-11.89) .. (-5.74,-11.98)
 .. controls (-4.85,-12.07) and (-4.48,-11.70) .. (-2.82,-12.11)
 .. controls (-1.23,-12.50) and (0.65,-12.76) .. (1.67,-12.96)
 .. controls (2.62,-13.14) and (2.92,-13.51) .. (3.33,-13.15)
 .. controls (3.72,-12.81) and (3.83,-12.32) .. (3.82,-11.60)
 .. controls (3.81,-10.87) and (4.09,-10.13) .. (4.39,-10.12)
),
1,((6.19,-5.85)
 .. controls (5.79,-5.84) and (3.50,-5.44) .. (2.54,-5.82)
 .. controls (1.49,-6.26) and (-0.80,-7.66) .. (-2.28,-8.07)
 .. controls (-3.76,-8.47) and (-4.30,-5.81) .. (-4.30,-5.81)
));
draw_downscrap;
endfig;
beginfig(25);
ATTR__survey := "50a-85.D35projet";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-6.01,-6.85)
 .. controls (-6.01,-6.85) and (-5.48,-7.66) .. (-5.85,-8.06)
 .. controls (-6.21,-8.47) and (-6.65,-11.89) .. (-5.74,-11.98)
 .. controls (-4.85,-12.07) and (-4.48,-11.70) .. (-2.82,-12.11)
 .. controls (-1.23,-12.50) and (0.65,-12.76) .. (1.67,-12.96)
 .. controls (2.62,-13.14) and (2.92,-13.51) .. (3.33,-13.15)
 .. controls (3.72,-12.81) and (3.83,-12.32) .. (3.82,-11.60)
 .. controls (3.81,-10.87) and (4.09,-10.13) .. (4.39,-10.12)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.19,-5.85)
 .. controls (5.79,-5.84) and (3.50,-5.44) .. (2.54,-5.82)
 .. controls (1.49,-6.26) and (-0.80,-7.66) .. (-2.28,-8.07)
 .. controls (-3.76,-8.47) and (-4.30,-5.81) .. (-4.30,-5.81)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((1.76,-4.67)
 -- (1.53,11.26)
));
endfig;
beginfig(26);
drawoptions();
p_label.top(btex \thlabel\thnormalsize \thfb\char80 \char49 \char51 \mainfont{} etex,(1.43,13.51),0.0,0);
endfig;
background:=(1.00000,0.72250,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.72250, 0.25000);
current_scrap := "50a-85SP5@50a-85.D35projet";
ATTR__scrap := "50a-85SP5";
beginfig(27);
draw_upscrap(1)(1,((-1.10,-7.45)
 .. controls (-1.10,-7.45) and (0.07,-8.26) .. (0.83,-8.26)
 .. controls (1.60,-8.26) and (2.72,-8.30) .. (3.49,-9.25)
 .. controls (4.25,-10.19) and (3.94,-13.30) .. (4.03,-13.93)
),
1,reverse ((-4.12,-10.87)
 .. controls (-4.12,-10.87) and (-4.25,-12.17) .. (-3.58,-12.58)
 .. controls (-2.90,-12.98) and (-1.82,-14.29) .. (-0.97,-14.20)
 .. controls (-0.11,-14.11) and (0.88,-14.02) .. (1.15,-14.20)
 .. controls (1.42,-14.38) and (2.32,-14.96) .. (2.32,-14.96)
));
draw_downscrap;
endfig;
beginfig(28);
ATTR__height := -1;
drawoptions();
l_rockedge(((1.33,-7.72)
 -- (1.42,12.85)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.12,-10.87)
 .. controls (-4.12,-10.87) and (-4.25,-12.17) .. (-3.58,-12.58)
 .. controls (-2.90,-12.98) and (-1.82,-14.29) .. (-0.97,-14.20)
 .. controls (-0.11,-14.11) and (0.88,-14.02) .. (1.15,-14.20)
 .. controls (1.42,-14.38) and (2.32,-14.96) .. (2.32,-14.96)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1.10,-7.45)
 .. controls (-1.10,-7.45) and (0.07,-8.26) .. (0.83,-8.26)
 .. controls (1.60,-8.26) and (2.72,-8.30) .. (3.49,-9.25)
 .. controls (4.25,-10.19) and (3.94,-13.30) .. (4.03,-13.93)
));
endfig;
beginfig(29);
drawoptions();
p_label.top(btex \thlabel\thnormalsize \thfb\char82 \char52 \mainfont{} etex,(1.46,14.96),0.0,0);
drawoptions();
p_label.llft(btex \thaltitude \thfb\char49 \char51 \char53 \char53 \mainfont{} etex,(-1.64,-14.02),0.0,1);
endfig;
background:=(1.00000,0.70000,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.70000, 0.25000);
current_scrap := "50a-85SP4@50a-85.D35projet";
ATTR__scrap := "50a-85SP4";
beginfig(30);
draw_upscrap(1)(1,((-4.50,-1.80)
 .. controls (-4.50,-1.80) and (-3.83,-4.05) .. (-3.92,-4.77)
 .. controls (-4.01,-5.49) and (-4.91,-6.03) .. (-5.00,-6.66)
 .. controls (-5.09,-7.29) and (-5.40,-11.97) .. (-3.51,-12.60)
 .. controls (-1.62,-13.23) and (-1.03,-13.32) .. (-0.58,-13.73)
 .. controls (-0.13,-14.13) and (2.61,-15.66) .. (2.38,-17.28)
),
1,((5.40,-13.86)
 .. controls (4.18,-13.19) and (2.88,-9.95) .. (2.34,-9.05)
 .. controls (1.80,-8.15) and (-0.09,-7.65) .. (-1.08,-7.20)
 .. controls (-2.07,-6.75) and (-2.48,-5.72) .. (-2.34,-5.18)
 .. controls (-2.21,-4.64) and (-2.88,-2.25) .. (-2.88,-2.25)
));
draw_downscrap;
endfig;
beginfig(31);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.50,-1.80)
 .. controls (-4.50,-1.80) and (-3.83,-4.05) .. (-3.92,-4.77)
 .. controls (-4.01,-5.49) and (-4.91,-6.03) .. (-5.00,-6.66)
 .. controls (-5.09,-7.29) and (-5.40,-11.97) .. (-3.51,-12.60)
 .. controls (-1.62,-13.23) and (-1.03,-13.32) .. (-0.58,-13.73)
 .. controls (-0.13,-14.13) and (2.61,-15.66) .. (2.38,-17.28)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((5.40,-13.86)
 .. controls (4.18,-13.19) and (2.88,-9.95) .. (2.34,-9.05)
 .. controls (1.80,-8.15) and (-0.09,-7.65) .. (-1.08,-7.20)
 .. controls (-2.07,-6.75) and (-2.48,-5.72) .. (-2.34,-5.18)
 .. controls (-2.21,-4.64) and (-2.88,-2.25) .. (-2.88,-2.25)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((2.47,-5.94)
 -- (2.47,15.35)
));
endfig;
beginfig(32);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char82 \char51 \mainfont{} etex,(2.56,17.28),0.0,0);
endfig;
background:=(1.00000,0.67750,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.67750, 0.25000);
current_scrap := "50a-85SP3@50a-85.D35projet";
ATTR__scrap := "50a-85SP3";
beginfig(33);
draw_upscrap(1)(1,((-2.25,-21.80)
 .. controls (-2.57,-20.96) and (-2.79,-18.29) .. (-2.97,-17.17)
 .. controls (-3.15,-16.04) and (-4.37,-13.93) .. (-4.55,-13.12)
 .. controls (-4.73,-12.31) and (-5.27,-10.46) .. (-5.58,-8.30)
 .. controls (-5.90,-6.14) and (-6.21,-4.79) .. (-6.12,-4.25)
 .. controls (-6.03,-3.71) and (-7.11,0.97) .. (-7.20,1.51)
 .. controls (-7.29,2.05) and (-9.00,7.58) .. (-9.14,8.93)
 .. controls (-9.27,10.28) and (-10.35,15.95) .. (-10.48,17.30)
 .. controls (-10.62,18.65) and (-11.02,21.80) .. (-11.02,21.80)
),
1,((-12.78,21.49)
 .. controls (-12.78,21.49) and (-12.24,18.38) .. (-11.97,16.09)
 .. controls (-11.70,13.79) and (-11.03,7.72) .. (-10.76,6.19)
 .. controls (-10.49,4.66) and (-9.32,0.29) .. (-9.32,-0.65)
 .. controls (-9.32,-1.60) and (-8.33,-3.85) .. (-8.15,-4.66)
 .. controls (-7.97,-5.47) and (-5.99,-12.85) .. (-5.58,-14.02)
 .. controls (-5.18,-15.19) and (-5.58,-15.28) .. (-5.04,-17.21)
 .. controls (-4.50,-19.15) and (-3.95,-20.08) .. (-3.87,-21.35)
));
draw_downscrap;
endfig;
beginfig(34);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2.25,-21.80)
 .. controls (-2.57,-20.96) and (-2.79,-18.29) .. (-2.97,-17.17)
 .. controls (-3.15,-16.04) and (-4.37,-13.93) .. (-4.55,-13.12)
 .. controls (-4.73,-12.31) and (-5.27,-10.46) .. (-5.58,-8.30)
 .. controls (-5.90,-6.14) and (-6.21,-4.79) .. (-6.12,-4.25)
 .. controls (-6.03,-3.71) and (-7.11,0.97) .. (-7.20,1.51)
 .. controls (-7.29,2.05) and (-9.00,7.58) .. (-9.14,8.93)
 .. controls (-9.27,10.28) and (-10.35,15.95) .. (-10.48,17.30)
 .. controls (-10.62,18.65) and (-11.02,21.80) .. (-11.02,21.80)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-5.99,10.55)
 -- (13.90,10.55)
));
drawoptions();
p_dig((-7.47,-21.40),0.0,1.00,(-1,-1));
drawoptions();
p_dig((-10.53,-9.02),0.0,1.00,(-1,-1));
drawoptions();
p_dig((-14.71,6.32),0.0,1.00,(-1,-1));
drawoptions();
p_dig((-16.42,17.84),0.0,1.00,(-1,-1));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-12.78,21.49)
 .. controls (-12.78,21.49) and (-12.24,18.38) .. (-11.97,16.09)
 .. controls (-11.70,13.79) and (-11.03,7.72) .. (-10.76,6.19)
 .. controls (-10.49,4.66) and (-9.32,0.29) .. (-9.32,-0.65)
 .. controls (-9.32,-1.60) and (-8.33,-3.85) .. (-8.15,-4.66)
 .. controls (-7.97,-5.47) and (-5.99,-12.85) .. (-5.58,-14.02)
 .. controls (-5.18,-15.19) and (-5.58,-15.28) .. (-5.04,-17.21)
 .. controls (-4.50,-19.15) and (-3.95,-20.08) .. (-3.87,-21.35)
));
endfig;
beginfig(35);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char66 \char111 \char121 \char97 \char117 \ \char100 \char101 \char115 \ \char71 \char97 \char98 \char105 \char111 \char110 \char115 \ \char51 \char51 \ \char109 \char58 \ \char50 \char52 \ \char115 \thfc\char233 \thfb\char97 \char110 \char99 \char101 \char115 \mainfont{} etex,(16.42,10.46),0.0,0);
endfig;
background:=(1.00000,0.65500,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.65500, 0.25000);
current_scrap := "50a-85SP2@50a-85.D35projet";
ATTR__scrap := "50a-85SP2";
beginfig(36);
ATTR__height := -1;
drawoptions();
l_pit(((-2.92,24.46)
 .. controls (-2.92,24.73) and (-3.24,26.08) .. (-3.28,26.44)
 .. controls (-3.33,26.80) and (-3.64,27.29) .. (-3.64,27.29)
));
ATTR__height := -1;
drawoptions();
l_pit(((-7.81,23.20)
 .. controls (-7.81,23.20) and (-7.24,22.52) .. (-6.12,22.16)
 .. controls (-4.99,21.80) and (-4.68,21.49) .. (-4.59,21.22)
));
endfig;
beginfig(37);
draw_upscrap(1)(1,((-3.76,15.61)
 .. controls (-3.76,15.61) and (-3.37,13.79) .. (-3.10,12.76)
 .. controls (-2.83,11.72) and (-2.47,8.62) .. (-2.25,7.90)
 .. controls (-2.03,7.18) and (-1.49,6.95) .. (-1.35,5.47)
 .. controls (-1.22,3.98) and (-0.41,2.45) .. (-0.23,2.09)
 .. controls (-0.05,1.73) and (1.44,-1.64) .. (1.57,-2.41)
 .. controls (1.71,-3.17) and (1.93,-8.57) .. (1.98,-8.98)
 .. controls (2.02,-9.38) and (1.66,-10.64) .. (1.93,-10.91)
 .. controls (2.20,-11.18) and (3.06,-11.18) .. (3.33,-11.36)
 .. controls (3.60,-11.54) and (4.00,-11.95) .. (4.00,-12.26)
 .. controls (4.00,-12.58) and (4.36,-16.27) .. (4.50,-16.85)
 .. controls (4.63,-17.44) and (5.53,-21.08) .. (5.62,-21.53)
 .. controls (5.71,-21.98) and (6.48,-26.35) .. (6.84,-27.29)
),
1,((8.59,-26.98)
 .. controls (8.50,-26.71) and (8.41,-25.49) .. (8.10,-24.64)
 .. controls (7.78,-23.78) and (8.37,-22.97) .. (8.05,-22.16)
 .. controls (7.74,-21.35) and (7.47,-20.50) .. (7.47,-20.50)
),
1,((7.47,-20.50)
 -- (7.47,-20.50)),
1,((7.47,-20.50)
 .. controls (7.11,-19.64) and (4.63,-8.84) .. (4.63,-8.84)
 .. controls (4.63,-8.84) and (3.28,-1.82) .. (3.01,-0.79)
 .. controls (2.74,0.25) and (0.76,7.49) .. (0.09,9.25)
 .. controls (-0.58,11.00) and (-1.48,14.49) .. (-1.48,14.49)
),
1,((-1.48,14.49)
 .. controls (-1.66,15.28) and (-1.66,16.06) .. (-1.75,16.87)
 .. controls (-1.84,17.68) and (-2.00,19.37) .. (-2.02,19.64)
 .. controls (-2.05,19.91) and (-2.02,21.08) .. (-2.16,21.98)
 .. controls (-2.29,22.88) and (-2.32,23.42) .. (-2.34,24.57)
 .. controls (-2.36,25.72) and (-2.56,27.11) .. (-2.56,27.11)
),
1,((-8.59,22.34)
 .. controls (-8.59,22.34) and (-8.35,21.31) .. (-6.73,21.33)
 .. controls (-5.11,21.35) and (-4.63,20.77) .. (-4.43,20.11)
 .. controls (-4.23,19.46) and (-3.94,18.09) .. (-3.91,17.66)
 .. controls (-3.89,17.23) and (-3.82,16.11) .. (-3.76,15.61)
));
draw_downscrap;
endfig;
beginfig(38);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-8.59,22.34)
 .. controls (-8.59,22.34) and (-8.35,21.31) .. (-6.73,21.33)
 .. controls (-5.11,21.35) and (-4.63,20.77) .. (-4.43,20.11)
 .. controls (-4.23,19.46) and (-3.94,18.09) .. (-3.91,17.66)
 .. controls (-3.89,17.23) and (-3.82,16.11) .. (-3.76,15.61)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1.48,14.49)
 .. controls (-1.66,15.28) and (-1.66,16.06) .. (-1.75,16.87)
 .. controls (-1.84,17.68) and (-2.00,19.37) .. (-2.02,19.64)
 .. controls (-2.05,19.91) and (-2.02,21.08) .. (-2.16,21.98)
 .. controls (-2.29,22.88) and (-2.32,23.42) .. (-2.34,24.57)
 .. controls (-2.36,25.72) and (-2.56,27.11) .. (-2.56,27.11)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((7.47,-20.50)
 .. controls (7.11,-19.64) and (4.63,-8.84) .. (4.63,-8.84)
 .. controls (4.63,-8.84) and (3.28,-1.82) .. (3.01,-0.79)
 .. controls (2.74,0.25) and (0.76,7.49) .. (0.09,9.25)
 .. controls (-0.58,11.00) and (-1.48,14.49) .. (-1.48,14.49)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((8.59,-26.98)
 .. controls (8.50,-26.71) and (8.41,-25.49) .. (8.10,-24.64)
 .. controls (7.78,-23.78) and (8.37,-22.97) .. (8.05,-22.16)
 .. controls (7.74,-21.35) and (7.47,-20.50) .. (7.47,-20.50)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.76,15.61)
 .. controls (-3.76,15.61) and (-3.37,13.79) .. (-3.10,12.76)
 .. controls (-2.83,11.72) and (-2.47,8.62) .. (-2.25,7.90)
 .. controls (-2.03,7.18) and (-1.49,6.95) .. (-1.35,5.47)
 .. controls (-1.22,3.98) and (-0.41,2.45) .. (-0.23,2.09)
 .. controls (-0.05,1.73) and (1.44,-1.64) .. (1.57,-2.41)
 .. controls (1.71,-3.17) and (1.93,-8.57) .. (1.98,-8.98)
 .. controls (2.02,-9.38) and (1.66,-10.64) .. (1.93,-10.91)
 .. controls (2.20,-11.18) and (3.06,-11.18) .. (3.33,-11.36)
 .. controls (3.60,-11.54) and (4.00,-11.95) .. (4.00,-12.26)
 .. controls (4.00,-12.58) and (4.36,-16.27) .. (4.50,-16.85)
 .. controls (4.63,-17.44) and (5.53,-21.08) .. (5.62,-21.53)
 .. controls (5.71,-21.98) and (6.48,-26.35) .. (6.84,-27.29)
));
drawoptions();
p_dig((1.48,-18.88),0.0,1.00,(-1,-1));
drawoptions();
p_dig((-2.70,-4.21),0.0,1.00,(-1,-1));
drawoptions();
p_airdraught_summer((3.33,8.66),22.2,1.00,(1,1));
drawoptions();
p_airdraught_winter((5.35,2.50),198.3,1.00,(1,1));
endfig;
beginfig(39);
drawoptions();
p_label.urt(btex \thaltitude \thsmallsize \thfb\char49 \char51 \char54 \char54 \mainfont{} etex,(6.43,-16.45),0.0,1);
endfig;
background:=(1.00000,0.60250,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.60250, 0.25000);
current_scrap := "50a-85SP1@50a-85.D35projet";
ATTR__scrap := "50a-85SP1";
beginfig(40);
ATTR__height := -1;
drawoptions();
l_pit(((15.67,-7.50)
 .. controls (15.67,-7.50) and (14.48,-6.00) .. (14.04,-5.02)
 .. controls (13.59,-4.03) and (12.25,-3.41) .. (11.71,-2.33)
 .. controls (11.17,-1.26) and (9.28,-2.18) .. (8.47,-0.92)
 .. controls (7.65,0.34) and (6.95,0.57) .. (6.59,2.01)
 .. controls (6.23,3.45) and (5.15,6.24) .. (5.15,6.24)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((5.43,-5.42)
 .. controls (5.43,-5.42) and (5.22,-6.26) .. (5.13,-6.57)
));
ATTR__height := -1;
drawoptions();
l_pit(((2.31,6.03)
 .. controls (2.31,6.03) and (2.62,5.02) .. (2.62,4.71)
 .. controls (2.62,4.39) and (2.67,3.85) .. (2.73,3.15)
 .. controls (2.80,2.46) and (3.26,-0.81) .. (3.39,-1.39)
 .. controls (3.52,-1.97) and (4.53,-4.22) .. (4.80,-4.47)
));
ATTR__height := -1;
drawoptions();
l_pit(((6.47,-5.55)
 .. controls (6.47,-5.55) and (8.49,-6.13) .. (8.77,-6.79)
 .. controls (9.10,-7.55) and (9.63,-7.78) .. (9.76,-8.46)
 .. controls (9.88,-9.12) and (10.38,-9.42) .. (10.70,-10.35)
 .. controls (11.03,-11.28) and (11.28,-11.46) .. (11.50,-11.59)
));
endfig;
beginfig(41);
draw_upscrap(1)(1,((16.75,-7.68)
 .. controls (16.75,-7.68) and (14.13,-2.12) .. (12.25,-1.50)
 .. controls (10.36,-0.88) and (8.80,-0.92) .. (8.26,0.88)
 .. controls (7.72,2.68) and (5.69,7.14) .. (5.60,8.04)
),
1,((5.60,8.04)
 .. controls (5.60,8.04) and (4.16,8.85) .. (3.89,10.65)
 .. controls (3.62,12.45) and (3.08,12.18) .. (3.08,12.18)
),
1,((1.73,11.10)
 .. controls (2.54,9.93) and (1.72,6.51) .. (1.72,6.51)
 .. controls (1.72,6.51) and (1.91,4.80) .. (2.53,1.20)
 .. controls (3.14,-2.40) and (2.75,-2.73) .. (3.61,-3.99)
 .. controls (4.46,-5.23) and (3.99,-5.58) .. (4.01,-6.48)
),
1,((7.89,-7.07)
 .. controls (8.30,-5.53) and (10.72,-12.45) .. (10.72,-12.45)
),
1,((16.75,-7.68)
 -- cycle
));
draw_downscrap;
endfig;
beginfig(42);
ATTR__height := -1;
drawoptions();
l_rockedge(((1.93,-1.01)
 -- (-15.16,-1.00)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((1.64,11.73)
 -- (-15.51,11.73)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((16.75,-7.68)
 .. controls (16.75,-7.68) and (14.13,-2.12) .. (12.25,-1.50)
 .. controls (10.36,-0.88) and (8.80,-0.92) .. (8.26,0.88)
 .. controls (7.72,2.68) and (5.69,7.14) .. (5.60,8.04)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((5.60,8.04)
 .. controls (5.60,8.04) and (4.16,8.85) .. (3.89,10.65)
 .. controls (3.62,12.45) and (3.08,12.18) .. (3.08,12.18)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((7.89,-7.07)
 .. controls (8.30,-5.53) and (10.72,-12.45) .. (10.72,-12.45)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1.73,11.10)
 .. controls (2.54,9.93) and (1.72,6.51) .. (1.72,6.51)
 .. controls (1.72,6.51) and (1.91,4.80) .. (2.53,1.20)
 .. controls (3.14,-2.40) and (2.75,-2.73) .. (3.61,-3.99)
 .. controls (4.46,-5.23) and (3.99,-5.58) .. (4.01,-6.48)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((16.75,-7.68)
 -- cycle
));
endfig;
beginfig(43);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char81 \char117 \char105 \char116 \char116 \char101 \ \char111 \char117 \ \char68 \char111 \char117 \char98 \char108 \char101 \char58 \ \char80 \char49 \char56 \mainfont{} etex,(-16.68,-0.91),0.0,0);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char105 \char109 \char112 \mainfont{} etex,(-16.75,11.64),0.0,0);
endfig;
background:=(0.52000,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.52000, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP15@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP15";
beginfig(44);
draw_upscrap(1)(1,((2.09,-1.24)
 .. controls (2.27,-1.05) and (1.90,-0.67) .. (1.61,-0.12)
 .. controls (1.29,0.48) and (1.94,2.93) .. (1.95,3.33)
 .. controls (1.96,3.74) and (2.79,5.34) .. (2.75,5.70)
 .. controls (2.71,6.06) and (3.03,7.26) .. (2.62,7.70)
 .. controls (2.20,8.15) and (2.53,10.01) .. (1.91,10.45)
),
1,((-5.11,5.36)
 .. controls (-5.11,5.36) and (-4.68,3.79) .. (-3.47,3.32)
 .. controls (-2.29,2.86) and (-2.16,1.93) .. (-1.95,1.15)
 .. controls (-1.74,0.37) and (-0.35,-0.51) .. (-0.32,-0.63)
 .. controls (-0.29,-0.75) and (0.11,-2.42) .. (-0.16,-2.70)
));
draw_downscrap;
endfig;
beginfig(45);
ATTR__survey := "D35_20160703.D35projet";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2.09,-1.24)
 .. controls (2.27,-1.05) and (1.90,-0.67) .. (1.61,-0.12)
 .. controls (1.29,0.48) and (1.94,2.93) .. (1.95,3.33)
 .. controls (1.96,3.74) and (2.79,5.34) .. (2.75,5.70)
 .. controls (2.71,6.06) and (3.03,7.26) .. (2.62,7.70)
 .. controls (2.20,8.15) and (2.53,10.01) .. (1.91,10.45)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.11,5.36)
 .. controls (-5.11,5.36) and (-4.68,3.79) .. (-3.47,3.32)
 .. controls (-2.29,2.86) and (-2.16,1.93) .. (-1.95,1.15)
 .. controls (-1.74,0.37) and (-0.35,-0.51) .. (-0.32,-0.63)
 .. controls (-0.29,-0.75) and (0.11,-2.42) .. (-0.16,-2.70)
));
endfig;
background:=(0.58750,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.58750, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP14@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP14";
beginfig(46);
draw_upscrap(1)(1,((13.95,9.52)
 .. controls (14.53,9.18) and (15.79,8.33) .. (16.38,7.40)
 .. controls (17.37,5.85) and (17.48,5.87) .. (18.09,5.47)
 .. controls (18.70,5.06) and (20.68,3.49) .. (20.79,1.96)
 .. controls (20.90,0.43) and (20.86,-3.20) .. (20.84,-3.67)
 .. controls (20.81,-4.14) and (20.54,-4.82) .. (20.12,-5.87)
 .. controls (19.69,-6.93) and (19.89,-8.62) .. (20.25,-9.07)
),
1,((27.27,-3.98)
 .. controls (26.15,-3.13) and (22.79,-2.41) .. (22.46,-1.42)
 .. controls (22.12,-0.43) and (22.79,4.50) .. (21.96,4.97)
 .. controls (21.13,5.44) and (19.26,6.30) .. (18.77,6.95)
 .. controls (18.27,7.60) and (18.41,8.28) .. (18.27,8.80)
 .. controls (18.14,9.31) and (17.82,8.75) .. (18.09,9.92)
));
draw_downscrap;
endfig;
beginfig(47);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((27.27,-3.98)
 .. controls (26.15,-3.13) and (22.79,-2.41) .. (22.46,-1.42)
 .. controls (22.12,-0.43) and (22.79,4.50) .. (21.96,4.97)
 .. controls (21.13,5.44) and (19.26,6.30) .. (18.77,6.95)
 .. controls (18.27,7.60) and (18.41,8.28) .. (18.27,8.80)
 .. controls (18.14,9.31) and (17.82,8.75) .. (18.09,9.92)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((13.95,9.52)
 .. controls (14.53,9.18) and (15.79,8.33) .. (16.38,7.40)
 .. controls (17.37,5.85) and (17.48,5.87) .. (18.09,5.47)
 .. controls (18.70,5.06) and (20.68,3.49) .. (20.79,1.96)
 .. controls (20.90,0.43) and (20.86,-3.20) .. (20.84,-3.67)
 .. controls (20.81,-4.14) and (20.54,-4.82) .. (20.12,-5.87)
 .. controls (19.69,-6.93) and (19.89,-8.62) .. (20.25,-9.07)
));
drawoptions();
p_airdraught_summer((15.41,2.74),28.8,1.00,(-1,-1));
ATTR__height := -1;
drawoptions();
l_rockedge(((19.53,-9.92)
 -- (-25.76,-9.86)
));
endfig;
beginfig(48);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char50 \char54 \char48 \mainfont{} etex,(16.94,6.39),0.0,1);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char80 \char55 \mainfont{} etex,(-27.27,-9.83),0.0,0);
endfig;
background:=(0.59500,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.59500, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP13@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP13";
beginfig(49);
draw_upscrap(1)(1,((29.86,8.52)
 .. controls (29.86,8.52) and (28.96,6.77) .. (28.95,5.92)
 .. controls (28.95,5.07) and (28.91,1.75) .. (29.03,0.58)
 .. controls (29.14,-0.53) and (29.90,-2.33) .. (29.22,-4.16)
 .. controls (28.54,-5.96) and (28.36,-6.68) .. (28.66,-7.37)
 .. controls (28.92,-7.99) and (29.42,-8.52) .. (29.42,-8.52)
),
1,reverse ((30.85,8.39)
 .. controls (30.85,8.39) and (30.48,6.95) .. (30.84,6.37)
 .. controls (31.20,5.79) and (31.59,5.04) .. (31.36,4.10)
 .. controls (31.13,3.16) and (30.18,2.61) .. (30.53,0.97)
 .. controls (30.85,-0.56) and (31.43,-3.10) .. (31.88,-4.47)
 .. controls (32.38,-5.97) and (33.39,-7.11) .. (33.49,-7.65)
));
draw_downscrap;
endfig;
beginfig(50);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((30.85,8.39)
 .. controls (30.85,8.39) and (30.48,6.95) .. (30.84,6.37)
 .. controls (31.20,5.79) and (31.59,5.04) .. (31.36,4.10)
 .. controls (31.13,3.16) and (30.18,2.61) .. (30.53,0.97)
 .. controls (30.85,-0.56) and (31.43,-3.10) .. (31.88,-4.47)
 .. controls (32.38,-5.97) and (33.39,-7.11) .. (33.49,-7.65)
));
drawoptions();
p_airdraught_summer((35.64,-3.99),21.4,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((26.49,-4.11)
 -- (-31.41,-4.25)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((29.86,8.52)
 .. controls (29.86,8.52) and (28.96,6.77) .. (28.95,5.92)
 .. controls (28.95,5.07) and (28.91,1.75) .. (29.03,0.58)
 .. controls (29.14,-0.53) and (29.90,-2.33) .. (29.22,-4.16)
 .. controls (28.54,-5.96) and (28.36,-6.68) .. (28.66,-7.37)
 .. controls (28.92,-7.99) and (29.42,-8.52) .. (29.42,-8.52)
));
endfig;
beginfig(51);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char54 \char53 \char48 \ \char108 \char112 \char115 \ \char48 \char51 \char47 \char48 \char55 \char47 \char50 \char48 \char49 \char54 \ \char49 \char57 \char58 \char51 \char48 \mainfont{} etex,(-35.64,-4.30),0.0,0);
endfig;
background:=(0.62500,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.62500, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP12@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP12";
beginfig(52);
ATTR__height := -1;
drawoptions();
l_floorstep(((34.36,-43.36)
 .. controls (32.69,-40.39) and (29.05,-42.28) .. (29.05,-42.28)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((22.79,1.96)
 .. controls (22.79,1.96) and (16.63,4.93) .. (18.11,-5.87)
));
endfig;
beginfig(53);
draw_upscrap(1)(1,((7.58,39.62)
 .. controls (7.58,39.62) and (7.36,35.48) .. (7.67,34.45)
 .. controls (7.99,33.41) and (10.28,25.81) .. (10.42,24.59)
 .. controls (10.55,23.38) and (11.41,21.71) .. (11.36,20.81)
 .. controls (11.32,19.91) and (10.82,18.16) .. (11.09,17.39)
 .. controls (11.36,16.63) and (10.82,15.10) .. (11.00,14.38)
 .. controls (11.18,13.66) and (12.53,8.03) .. (12.80,7.22)
 .. controls (13.07,6.41) and (16.27,2.45) .. (17.26,-0.83)
 .. controls (18.25,-4.12) and (19.87,-2.86) .. (20.32,-4.21)
 .. controls (20.77,-5.56) and (23.65,-10.42) .. (23.51,-13.52)
 .. controls (23.38,-16.63) and (25.67,-25.36) .. (26.39,-27.83)
 .. controls (27.11,-30.31) and (30.22,-37.10) .. (30.22,-38.23)
 .. controls (30.22,-39.35) and (31.39,-40.88) .. (30.53,-42.86)
),
1,((31.52,-43.00)
 .. controls (31.52,-42.73) and (32.06,-42.32) .. (32.69,-42.01)
 .. controls (33.32,-41.69) and (34.36,-40.70) .. (34.36,-40.12)
 .. controls (34.36,-39.53) and (33.14,-31.79) .. (32.65,-29.99)
 .. controls (32.15,-28.19) and (31.16,-25.49) .. (31.16,-24.46)
 .. controls (31.16,-23.42) and (28.91,-18.79) .. (28.19,-16.76)
),
1,((28.19,-16.76)
 .. controls (27.47,-14.74) and (27.20,-11.41) .. (27.16,-10.19)
 .. controls (27.11,-8.98) and (24.91,-3.22) .. (24.77,-2.50)
 .. controls (24.64,-1.78) and (22.43,0.02) .. (21.94,0.83)
),
1,((21.94,0.83)
 .. controls (21.44,1.64) and (17.98,7.76) .. (17.57,8.44)
),
1,((17.57,8.44)
 .. controls (17.17,9.11) and (14.33,14.33) .. (14.15,15.77)
 .. controls (13.97,17.21) and (14.11,19.77) .. (13.52,21.22)
 .. controls (13.03,22.43) and (12.53,25.63) .. (12.31,26.21)
 .. controls (12.08,26.80) and (9.61,31.21) .. (9.56,31.57)
 .. controls (9.52,31.93) and (8.80,35.21) .. (8.80,37.06)
),
1,((8.80,37.06)
 .. controls (9.34,39.58) and (9.47,41.24) .. (9.47,41.24)
 -- (9.38,43.00)
),
1,((6.41,43.36)
 .. controls (6.41,43.36) and (6.91,41.96) .. (7.18,41.74)
 .. controls (7.45,41.51) and (7.58,39.62) .. (7.58,39.62)
));
draw_downscrap;
endfig;
beginfig(54);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((31.52,-43.00)
 .. controls (31.52,-42.73) and (32.06,-42.32) .. (32.69,-42.01)
 .. controls (33.32,-41.69) and (34.36,-40.70) .. (34.36,-40.12)
 .. controls (34.36,-39.53) and (33.14,-31.79) .. (32.65,-29.99)
 .. controls (32.15,-28.19) and (31.16,-25.49) .. (31.16,-24.46)
 .. controls (31.16,-23.42) and (28.91,-18.79) .. (28.19,-16.76)
));
ATTR__height := -1;
drawoptions();
l_wall_debris(((28.19,-16.76)
 .. controls (27.47,-14.74) and (27.20,-11.41) .. (27.16,-10.19)
 .. controls (27.11,-8.98) and (24.91,-3.22) .. (24.77,-2.50)
 .. controls (24.64,-1.78) and (22.43,0.02) .. (21.94,0.83)
));
drawoptions();
p_moonmilk((22.75,-4.75),0.0,0.50,(0,0));
drawoptions();
p_moonmilk((26.21,-16.81),0.0,0.50,(0,0));
drawoptions();
p_moonmilk((29.45,-28.42),0.0,0.50,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((21.94,0.83)
 .. controls (21.44,1.64) and (17.98,7.76) .. (17.57,8.44)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((17.57,8.44)
 .. controls (17.17,9.11) and (14.33,14.33) .. (14.15,15.77)
 .. controls (13.97,17.21) and (14.11,19.77) .. (13.52,21.22)
 .. controls (13.03,22.43) and (12.53,25.63) .. (12.31,26.21)
 .. controls (12.08,26.80) and (9.61,31.21) .. (9.56,31.57)
 .. controls (9.52,31.93) and (8.80,35.21) .. (8.80,37.06)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((21.58,-11.18)
 -- (-31.16,-11.18)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((8.08,30.80)
 -- (-31.07,30.71)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((16.99,-5.02)
 -- (-31.16,-5.02)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((27.70,-43.36)
 -- (-30.89,-43.36)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((7.58,39.62)
 .. controls (7.58,39.62) and (7.36,35.48) .. (7.67,34.45)
 .. controls (7.99,33.41) and (10.28,25.81) .. (10.42,24.59)
 .. controls (10.55,23.38) and (11.41,21.71) .. (11.36,20.81)
 .. controls (11.32,19.91) and (10.82,18.16) .. (11.09,17.39)
 .. controls (11.36,16.63) and (10.82,15.10) .. (11.00,14.38)
 .. controls (11.18,13.66) and (12.53,8.03) .. (12.80,7.22)
 .. controls (13.07,6.41) and (16.27,2.45) .. (17.26,-0.83)
 .. controls (18.25,-4.12) and (19.87,-2.86) .. (20.32,-4.21)
 .. controls (20.77,-5.56) and (23.65,-10.42) .. (23.51,-13.52)
 .. controls (23.38,-16.63) and (25.67,-25.36) .. (26.39,-27.83)
 .. controls (27.11,-30.31) and (30.22,-37.10) .. (30.22,-38.23)
 .. controls (30.22,-39.35) and (31.39,-40.88) .. (30.53,-42.86)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.41,43.36)
 .. controls (6.41,43.36) and (6.91,41.96) .. (7.18,41.74)
 .. controls (7.45,41.51) and (7.58,39.62) .. (7.58,39.62)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((8.80,37.06)
 .. controls (9.34,39.58) and (9.47,41.24) .. (9.47,41.24)
 -- (9.38,43.00)
));
endfig;
beginfig(55);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char83 \char113 \char117 \char101 \char108 \char101 \char116 \char116 \char101 \ \char99 \char104 \char97 \char117 \char118 \char101 \ \char115 \char111 \char117 \char114 \char105 \char115 \mainfont{} etex,(-34.27,-11.23),0.0,0);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char98 \char97 \char115 \ \char100 \char101 \ \char109 \thfc\char233 \thfb\char97 \char110 \char100 \char114 \char101 \ \thfc\char233 \thfb\char116 \char114 \char111 \char105 \char116 \mainfont{} etex,(-34.36,30.89),0.0,0);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char50 \char54 \char52 \mainfont{} etex,(25.18,-23.38),0.0,1);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char82 \char50 \mainfont{} etex,(-34.27,-4.84),0.0,0);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char82 \char51 \mainfont{} etex,(-34.22,-43.31),0.0,0);
endfig;
background:=(0.66250,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.66250, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP11@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP11";
beginfig(56);
draw_upscrap(1)(1,((0.91,55.63)
 .. controls (0.91,55.63) and (-1.62,55.19) .. (-0.94,52.90)
 .. controls (-0.27,50.61) and (1.44,49.71) .. (2.48,49.26)
 .. controls (3.51,48.81) and (2.70,47.55) .. (3.15,46.20)
 .. controls (3.60,44.85) and (8.96,42.10) .. (9.09,39.18)
 .. controls (9.23,36.25) and (8.41,29.87) .. (9.18,27.48)
 .. controls (9.94,25.09) and (12.55,13.26) .. (13.41,11.14)
 .. controls (14.26,9.03) and (15.21,7.14) .. (15.21,5.11)
 .. controls (15.21,3.09) and (15.21,-2.71) .. (16.69,-5.77)
 .. controls (18.18,-8.83) and (20.16,-12.12) .. (20.61,-15.76)
 .. controls (21.06,-19.41) and (21.96,-20.62) .. (22.50,-23.01)
 .. controls (23.04,-25.39) and (24.30,-31.42) .. (24.16,-32.68)
 .. controls (24.03,-33.94) and (23.89,-38.94) .. (25.20,-41.14)
 .. controls (26.50,-43.35) and (25.87,-48.66) .. (26.95,-50.82)
 .. controls (28.03,-52.98) and (27.94,-52.84) .. (28.57,-53.47)
 .. controls (29.20,-54.10) and (30.10,-55.05) .. (30.28,-55.63)
),
1,((34.96,-53.97)
 .. controls (34.29,-52.89) and (33.48,-50.23) .. (30.24,-47.35)
 .. controls (27.58,-44.99) and (26.91,-42.40) .. (25.96,-40.15)
 .. controls (25.02,-37.90) and (25.83,-32.10) .. (26.10,-30.66)
 .. controls (26.37,-29.22) and (23.67,-21.79) .. (23.53,-20.22)
 .. controls (23.40,-18.64) and (22.77,-13.29) .. (22.41,-11.80)
 .. controls (22.05,-10.32) and (19.75,-5.82) .. (19.53,-4.38)
 .. controls (19.30,-2.94) and (18.72,2.95) .. (18.04,5.83)
 .. controls (17.37,8.71) and (15.61,13.26) .. (15.48,16.95)
 .. controls (15.34,20.64) and (13.86,26.85) .. (13.63,29.05)
 .. controls (13.41,31.26) and (10.94,37.51) .. (11.21,39.85)
 .. controls (11.48,42.19) and (10.08,46.38) .. (9.59,48.22)
 .. controls (9.09,50.07) and (4.50,50.34) .. (3.65,50.79)
 .. controls (2.79,51.24) and (0.99,51.87) .. (0.50,52.86)
 .. controls (0.00,53.85) and (3.11,54.70) .. (3.11,54.70)
));
draw_downscrap;
endfig;
beginfig(57);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((34.96,-53.97)
 .. controls (34.29,-52.89) and (33.48,-50.23) .. (30.24,-47.35)
 .. controls (27.58,-44.99) and (26.91,-42.40) .. (25.96,-40.15)
 .. controls (25.02,-37.90) and (25.83,-32.10) .. (26.10,-30.66)
 .. controls (26.37,-29.22) and (23.67,-21.79) .. (23.53,-20.22)
 .. controls (23.40,-18.64) and (22.77,-13.29) .. (22.41,-11.80)
 .. controls (22.05,-10.32) and (19.75,-5.82) .. (19.53,-4.38)
 .. controls (19.30,-2.94) and (18.72,2.95) .. (18.04,5.83)
 .. controls (17.37,8.71) and (15.61,13.26) .. (15.48,16.95)
 .. controls (15.34,20.64) and (13.86,26.85) .. (13.63,29.05)
 .. controls (13.41,31.26) and (10.94,37.51) .. (11.21,39.85)
 .. controls (11.48,42.19) and (10.08,46.38) .. (9.59,48.22)
 .. controls (9.09,50.07) and (4.50,50.34) .. (3.65,50.79)
 .. controls (2.79,51.24) and (0.99,51.87) .. (0.50,52.86)
 .. controls (0.00,53.85) and (3.11,54.70) .. (3.11,54.70)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((18.76,-18.87)
 -- (-17.50,-18.87)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-17.50,-18.87)
 -- (-33.61,-2.67)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((0.91,55.63)
 .. controls (0.91,55.63) and (-1.62,55.19) .. (-0.94,52.90)
 .. controls (-0.27,50.61) and (1.44,49.71) .. (2.48,49.26)
 .. controls (3.51,48.81) and (2.70,47.55) .. (3.15,46.20)
 .. controls (3.60,44.85) and (8.96,42.10) .. (9.09,39.18)
 .. controls (9.23,36.25) and (8.41,29.87) .. (9.18,27.48)
 .. controls (9.94,25.09) and (12.55,13.26) .. (13.41,11.14)
 .. controls (14.26,9.03) and (15.21,7.14) .. (15.21,5.11)
 .. controls (15.21,3.09) and (15.21,-2.71) .. (16.69,-5.77)
 .. controls (18.18,-8.83) and (20.16,-12.12) .. (20.61,-15.76)
 .. controls (21.06,-19.41) and (21.96,-20.62) .. (22.50,-23.01)
 .. controls (23.04,-25.39) and (24.30,-31.42) .. (24.16,-32.68)
 .. controls (24.03,-33.94) and (23.89,-38.94) .. (25.20,-41.14)
 .. controls (26.50,-43.35) and (25.87,-48.66) .. (26.95,-50.82)
 .. controls (28.03,-52.98) and (27.94,-52.84) .. (28.57,-53.47)
 .. controls (29.20,-54.10) and (30.10,-55.05) .. (30.28,-55.63)
));
endfig;
beginfig(58);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char49 \char50 \char55 \char50 \mainfont{} etex,(10.58,44.35),0.0,1);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char50 \char55 \char48 \mainfont{} etex,(25.83,-43.12),0.0,1);
drawoptions();
p_label.ulft(btex \thlabel\thnormalsize \thfb\char71 \char114 \char111 \char115 \char115 \char101 \char115 \ \thfc\char233 \thfb\char99 \char97 \char105 \char108 \char108 \char101 \char115 \mainfont{} etex,(-34.96,-0.73),0.0,0);
endfig;
background:=(0.69250,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.69250, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP10@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP10";
beginfig(59);
ATTR__height := -1;
drawoptions();
l_pit(((-2.58,47.67)
 .. controls (-2.58,47.67) and (-5.06,45.64) .. (-3.98,44.84)
 .. controls (-2.27,43.58) and (-2.27,43.58) .. (-1.23,43.62)
 .. controls (0.05,43.68) and (-0.96,43.80) .. (0.57,44.79)
));
ATTR__height := -1;
drawoptions();
l_pit(((0.57,44.79)
 .. controls (0.57,44.79) and (2.10,46.71) .. (2.23,47.72)
 .. controls (2.41,49.07) and (2.32,48.93) .. (2.37,49.34)
 .. controls (2.41,49.74) and (1.78,50.37) .. (1.02,49.79)
 .. controls (0.32,49.25) and (-1.95,48.41) .. (-2.58,47.67)
));
endfig;
beginfig(60);
draw_upscrap(1)(1,((28.42,-51.18)
 .. controls (29.65,-51.23) and (30.29,-50.05) .. (31.46,-49.64)
 .. controls (32.64,-49.23) and (26.28,-44.70) .. (24.96,-44.11)
 .. controls (23.65,-43.53) and (22.61,-43.00) .. (21.89,-41.29)
 .. controls (21.18,-39.58) and (20.68,-34.81) .. (19.83,-33.78)
 .. controls (18.97,-32.74) and (19.33,-31.75) .. (19.29,-30.94)
 .. controls (19.24,-30.13) and (17.31,-22.84) .. (17.40,-20.68)
 .. controls (17.49,-18.52) and (19.47,-17.44) .. (21.04,-17.08)
 .. controls (22.62,-16.72) and (22.66,-6.96) .. (23.25,-1.87)
 .. controls (23.83,3.21) and (17.17,13.65) .. (16.81,14.87)
 .. controls (16.45,16.08) and (14.52,21.12) .. (13.62,23.60)
 .. controls (12.72,26.07) and (11.41,31.52) .. (10.65,33.36)
 .. controls (9.88,35.21) and (6.60,41.01) .. (6.19,43.17)
 .. controls (5.79,45.33) and (4.75,45.83) .. (4.17,46.77)
 .. controls (3.58,47.72) and (4.39,50.01) .. (4.39,50.01)
),
1,((1.11,51.23)
 .. controls (0.21,50.37) and (-8.16,46.73) .. (-4.88,44.21)
 .. controls (-1.89,41.91) and (-2.00,42.23) .. (-2.00,42.23)
),
1,((2.14,42.63)
 .. controls (2.14,42.63) and (2.17,43.49) .. (2.10,45.06)
 .. controls (2.05,46.01) and (2.73,44.66) .. (2.73,44.66)
),
1,((2.73,44.66)
 .. controls (4.84,43.62) and (4.08,43.40) .. (4.17,42.32)
 .. controls (4.26,41.24) and (5.83,33.77) .. (6.73,31.79)
 .. controls (7.63,29.81) and (10.69,24.45) .. (10.92,22.88)
 .. controls (11.14,21.30) and (13.17,14.19) .. (14.47,12.08)
 .. controls (15.78,9.96) and (19.65,3.26) .. (20.32,1.55)
 .. controls (21.00,-0.16) and (21.63,-2.41) .. (21.22,-6.28)
 .. controls (20.82,-10.15) and (20.95,-14.97) .. (18.70,-16.41)
 .. controls (16.45,-17.85) and (14.65,-18.79) .. (15.10,-21.58)
 .. controls (15.55,-24.37) and (15.64,-29.23) .. (15.87,-31.12)
 .. controls (16.09,-33.01) and (17.22,-33.91) .. (17.44,-35.98)
 .. controls (17.67,-38.05) and (18.03,-42.60) .. (19.42,-44.13)
 .. controls (20.82,-45.65) and (22.66,-46.65) .. (24.15,-47.33)
 .. controls (25.65,-48.00) and (29.10,-49.23) .. (25.96,-50.31)
));
draw_downscrap;
endfig;
beginfig(61);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((28.42,-51.18)
 .. controls (29.65,-51.23) and (30.29,-50.05) .. (31.46,-49.64)
 .. controls (32.64,-49.23) and (26.28,-44.70) .. (24.96,-44.11)
 .. controls (23.65,-43.53) and (22.61,-43.00) .. (21.89,-41.29)
 .. controls (21.18,-39.58) and (20.68,-34.81) .. (19.83,-33.78)
 .. controls (18.97,-32.74) and (19.33,-31.75) .. (19.29,-30.94)
 .. controls (19.24,-30.13) and (17.31,-22.84) .. (17.40,-20.68)
 .. controls (17.49,-18.52) and (19.47,-17.44) .. (21.04,-17.08)
 .. controls (22.62,-16.72) and (22.66,-6.96) .. (23.25,-1.87)
 .. controls (23.83,3.21) and (17.17,13.65) .. (16.81,14.87)
 .. controls (16.45,16.08) and (14.52,21.12) .. (13.62,23.60)
 .. controls (12.72,26.07) and (11.41,31.52) .. (10.65,33.36)
 .. controls (9.88,35.21) and (6.60,41.01) .. (6.19,43.17)
 .. controls (5.79,45.33) and (4.75,45.83) .. (4.17,46.77)
 .. controls (3.58,47.72) and (4.39,50.01) .. (4.39,50.01)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2.73,44.66)
 .. controls (4.84,43.62) and (4.08,43.40) .. (4.17,42.32)
 .. controls (4.26,41.24) and (5.83,33.77) .. (6.73,31.79)
 .. controls (7.63,29.81) and (10.69,24.45) .. (10.92,22.88)
 .. controls (11.14,21.30) and (13.17,14.19) .. (14.47,12.08)
 .. controls (15.78,9.96) and (19.65,3.26) .. (20.32,1.55)
 .. controls (21.00,-0.16) and (21.63,-2.41) .. (21.22,-6.28)
 .. controls (20.82,-10.15) and (20.95,-14.97) .. (18.70,-16.41)
 .. controls (16.45,-17.85) and (14.65,-18.79) .. (15.10,-21.58)
 .. controls (15.55,-24.37) and (15.64,-29.23) .. (15.87,-31.12)
 .. controls (16.09,-33.01) and (17.22,-33.91) .. (17.44,-35.98)
 .. controls (17.67,-38.05) and (18.03,-42.60) .. (19.42,-44.13)
 .. controls (20.82,-45.65) and (22.66,-46.65) .. (24.15,-47.33)
 .. controls (25.65,-48.00) and (29.10,-49.23) .. (25.96,-50.31)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1.11,51.23)
 .. controls (0.21,50.37) and (-8.16,46.73) .. (-4.88,44.21)
 .. controls (-1.89,41.91) and (-2.00,42.23) .. (-2.00,42.23)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2.14,42.63)
 .. controls (2.14,42.63) and (2.17,43.49) .. (2.10,45.06)
 .. controls (2.05,46.01) and (2.73,44.66) .. (2.73,44.66)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-4.20,42.95)
 -- (-28.73,42.95)
));
endfig;
beginfig(62);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char50 \char55 \char52 \mainfont{} etex,(15.55,-25.81),0.0,1);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char100 \char101 \ \char108 \char97 \ \char112 \char101 \char117 \char114 \char58 \ \ \char80 \char49 \char53 \mainfont{} etex,(-32.64,42.95),0.0,0);
endfig;
background:=(0.72250,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.72250, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP9@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP9";
beginfig(63);
current_src := "D35_20160703.th2 [644]";
string area_border[];
area_border[1] := "l260-1285-4262";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-20.47,23.44)
 .. controls (-20.47,23.44) and (-19.21,22.68) .. (-19.48,21.24)
 .. controls (-19.75,19.80) and (-17.64,18.31) .. (-17.64,18.31)
 -- (-17.01,13.14)
 .. controls (-17.01,13.14) and (-7.65,12.78) .. (-6.93,13.86)
 .. controls (-6.21,14.94) and (-10.30,25.96) .. (-10.30,25.96)
 -- cycle
)));
ATTR__id := "l260-1285-4262";
ATTR__height := -1;
drawoptions();
l_border_visible(((-20.47,23.44)
 .. controls (-20.47,23.44) and (-19.21,22.68) .. (-19.48,21.24)
 .. controls (-19.75,19.80) and (-17.64,18.31) .. (-17.64,18.31)
 -- (-17.01,13.14)
 .. controls (-17.01,13.14) and (-7.65,12.78) .. (-6.93,13.86)
 .. controls (-6.21,14.94) and (-10.30,25.96) .. (-10.30,25.96)
 -- cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_floorstep(((-15.34,11.16)
 .. controls (-15.12,11.20) and (-10.98,12.96) .. (-9.85,12.19)
 .. controls (-8.73,11.43) and (-6.30,12.01) .. (-4.90,12.28)
));
ATTR__height := -1;
drawoptions();
l_pit(((-2.52,-11.11)
 .. controls (-2.61,-12.01) and (-2.07,-13.10) .. (-1.89,-13.18)
 .. controls (-0.87,-13.65) and (-0.85,-12.64) .. (-1.30,-11.70)
 .. controls (-1.75,-10.75) and (-2.42,-10.08) .. cycle
));
endfig;
beginfig(64);
draw_upscrap(1)(1,((-23.26,45.18)
 .. controls (-23.26,45.18) and (-21.82,43.47) .. (-21.24,42.03)
 .. controls (-20.65,40.59) and (-20.29,39.06) .. (-19.75,37.75)
 .. controls (-19.21,36.45) and (-18.72,34.20) .. (-18.40,33.16)
 .. controls (-18.09,32.13) and (-17.19,30.06) .. (-17.01,29.25)
 .. controls (-16.83,28.44) and (-15.93,26.28) .. (-16.15,25.69)
 .. controls (-16.38,25.11) and (-15.70,19.30) .. (-15.25,16.87)
 .. controls (-14.80,14.44) and (-13.09,10.17) .. (-12.42,8.73)
 .. controls (-11.74,7.29) and (-10.12,6.75) .. (-9.63,5.53)
 .. controls (-9.13,4.32) and (-7.96,2.21) .. (-7.47,0.68)
 .. controls (-6.97,-0.85) and (-5.22,-5.98) .. (-4.27,-7.92)
 .. controls (-3.48,-9.56) and (-2.29,-12.73) .. (-1.98,-13.90)
 .. controls (-1.66,-15.07) and (2.11,-24.48) .. (2.34,-26.41)
 .. controls (2.56,-28.35) and (5.58,-40.45) .. (6.98,-40.72)
 .. controls (8.37,-40.99) and (9.63,-40.72) .. (10.39,-40.41)
 .. controls (11.16,-40.09) and (12.15,-39.51) .. (13.63,-41.13)
 .. controls (15.12,-42.75) and (17.86,-44.77) .. (17.23,-45.67)
),
1,((20.52,-46.89)
 .. controls (20.56,-46.62) and (19.75,-44.50) .. (19.84,-43.42)
 .. controls (19.93,-42.34) and (15.43,-39.87) .. (14.40,-39.24)
 .. controls (13.36,-38.61) and (12.15,-38.20) .. (9.54,-37.03)
 .. controls (6.93,-35.86) and (8.01,-32.04) .. (7.11,-30.73)
 .. controls (6.21,-29.43) and (5.13,-26.23) .. (4.86,-24.93)
 .. controls (4.59,-23.62) and (1.58,-15.97) .. (0.95,-14.26)
 .. controls (0.32,-12.55) and (-0.54,-8.95) .. (-1.12,-6.48)
 .. controls (-1.71,-4.00) and (-2.83,-1.48) .. (-2.97,-0.49)
 .. controls (-3.10,0.50) and (-4.45,3.01) .. (-4.45,3.01)
),
1,((-4.45,3.01)
 .. controls (-5.08,4.14) and (-6.25,7.47) .. (-6.88,9.31)
 .. controls (-7.51,11.16) and (-7.51,10.93) .. (-7.78,12.55)
 .. controls (-8.05,14.17) and (-8.64,14.76) .. (-8.77,16.24)
 .. controls (-8.91,17.73) and (-11.47,24.84) .. (-12.24,26.50)
 .. controls (-13.00,28.17) and (-12.88,27.65) .. (-13.63,29.74)
 .. controls (-14.44,31.99) and (-13.86,30.91) .. (-14.13,31.36)
 .. controls (-14.40,31.81) and (-16.65,38.74) .. (-18.00,41.13)
 .. controls (-19.35,43.51) and (-19.53,46.89) .. (-19.53,46.89)
));
draw_downscrap;
endfig;
beginfig(65);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.45,3.01)
 .. controls (-5.08,4.14) and (-6.25,7.47) .. (-6.88,9.31)
 .. controls (-7.51,11.16) and (-7.51,10.93) .. (-7.78,12.55)
 .. controls (-8.05,14.17) and (-8.64,14.76) .. (-8.77,16.24)
 .. controls (-8.91,17.73) and (-11.47,24.84) .. (-12.24,26.50)
 .. controls (-13.00,28.17) and (-12.88,27.65) .. (-13.63,29.74)
 .. controls (-14.44,31.99) and (-13.86,30.91) .. (-14.13,31.36)
 .. controls (-14.40,31.81) and (-16.65,38.74) .. (-18.00,41.13)
 .. controls (-19.35,43.51) and (-19.53,46.89) .. (-19.53,46.89)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((0.72,-10.62)
 -- (3.42,-7.61)
 -- (21.37,-7.65)
));
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((-3.51,-12.96),0.0,1.00,(-1,-1));
ATTR__height := -1;
drawoptions();
l_rockedge(((-12.87,31.68)
 -- (18.36,31.72)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-23.26,45.18)
 .. controls (-23.26,45.18) and (-21.82,43.47) .. (-21.24,42.03)
 .. controls (-20.65,40.59) and (-20.29,39.06) .. (-19.75,37.75)
 .. controls (-19.21,36.45) and (-18.72,34.20) .. (-18.40,33.16)
 .. controls (-18.09,32.13) and (-17.19,30.06) .. (-17.01,29.25)
 .. controls (-16.83,28.44) and (-15.93,26.28) .. (-16.15,25.69)
 .. controls (-16.38,25.11) and (-15.70,19.30) .. (-15.25,16.87)
 .. controls (-14.80,14.44) and (-13.09,10.17) .. (-12.42,8.73)
 .. controls (-11.74,7.29) and (-10.12,6.75) .. (-9.63,5.53)
 .. controls (-9.13,4.32) and (-7.96,2.21) .. (-7.47,0.68)
 .. controls (-6.97,-0.85) and (-5.22,-5.98) .. (-4.27,-7.92)
 .. controls (-3.48,-9.56) and (-2.29,-12.73) .. (-1.98,-13.90)
 .. controls (-1.66,-15.07) and (2.11,-24.48) .. (2.34,-26.41)
 .. controls (2.56,-28.35) and (5.58,-40.45) .. (6.98,-40.72)
 .. controls (8.37,-40.99) and (9.63,-40.72) .. (10.39,-40.41)
 .. controls (11.16,-40.09) and (12.15,-39.51) .. (13.63,-41.13)
 .. controls (15.12,-42.75) and (17.86,-44.77) .. (17.23,-45.67)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((20.52,-46.89)
 .. controls (20.56,-46.62) and (19.75,-44.50) .. (19.84,-43.42)
 .. controls (19.93,-42.34) and (15.43,-39.87) .. (14.40,-39.24)
 .. controls (13.36,-38.61) and (12.15,-38.20) .. (9.54,-37.03)
 .. controls (6.93,-35.86) and (8.01,-32.04) .. (7.11,-30.73)
 .. controls (6.21,-29.43) and (5.13,-26.23) .. (4.86,-24.93)
 .. controls (4.59,-23.62) and (1.58,-15.97) .. (0.95,-14.26)
 .. controls (0.32,-12.55) and (-0.54,-8.95) .. (-1.12,-6.48)
 .. controls (-1.71,-4.00) and (-2.83,-1.48) .. (-2.97,-0.49)
 .. controls (-3.10,0.50) and (-4.45,3.01) .. (-4.45,3.01)
));
endfig;
beginfig(66);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char50 \char55 \char57 \mainfont{} etex,(-4.77,-6.97),0.0,1);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char110 \char111 \char110 \ \char100 \char101 \char115 \char99 \char101 \char110 \char100 \char117 \ \char40 \char109 \char105 \char110 \char105 \ \char97 \char99 \char116 \char105 \char102 \char41 \mainfont{} etex,(23.26,-7.70),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char69 \char110 \char116 \char114 \thfc\char233 \thfb\char101 \ \char109 \thfc\char233 \thfb\char97 \char110 \char100 \char114 \char101 \ \char70 \char114 \char97 \char110 \char99 \char101 \char45 \char73 \char115 \char108 \char97 \char110 \char100 \char101 \mainfont{} etex,(22.50,31.63),0.0,0);
endfig;
background:=(0.75250,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.75250, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP8@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP8";
beginfig(67);
ATTR__height := -1;
drawoptions();
l_floormeander(((-31.61,3.85)
 .. controls (-30.58,3.49) and (-29.23,2.32) .. (-28.46,1.37)
 .. controls (-27.70,0.43) and (-27.11,0.56) .. (-26.30,-0.02)
 .. controls (-25.49,-0.61) and (-22.97,-1.78) .. (-22.79,-1.82)
));
endfig;
beginfig(68);
draw_upscrap(1)(1,((-7.54,-11.32)
 .. controls (-7.54,-11.32) and (-8.35,-9.97) .. (-8.08,-8.48)
 .. controls (-7.81,-7.00) and (-8.08,-5.96) .. (-7.99,-5.11)
 .. controls (-7.90,-4.25) and (-6.68,-1.96) .. (-6.23,0.07)
 .. controls (-5.78,2.09) and (-5.15,3.44) .. (-5.69,4.21)
 .. controls (-6.23,4.97) and (-8.57,13.03) .. (-9.38,13.03)
 .. controls (-9.86,13.03) and (-12.62,11.41) .. (-12.44,9.43)
 .. controls (-12.26,7.45) and (-12.62,6.86) .. (-12.49,5.56)
 .. controls (-12.35,4.25) and (-11.45,0.83) .. (-12.80,1.51)
 .. controls (-14.15,2.18) and (-16.67,4.39) .. (-16.67,4.39)
 .. controls (-16.67,4.39) and (-18.11,4.25) .. (-18.16,2.59)
 .. controls (-18.20,0.92) and (-18.02,-0.38) .. (-18.97,-0.25)
 .. controls (-19.91,-0.11) and (-22.66,0.74) .. (-23.24,1.10)
 .. controls (-23.83,1.46) and (-25.04,1.73) .. (-25.99,2.63)
 .. controls (-26.93,3.53) and (-30.58,5.74) .. (-30.58,5.74)
),
1,((-34.44,2.54)
 .. controls (-34.44,2.54) and (-32.38,0.61) .. (-31.21,-0.38)
 .. controls (-30.04,-1.37) and (-29.23,-2.77) .. (-29.00,-3.08)
 .. controls (-28.63,-3.61) and (-28.15,-3.98) .. (-28.10,-4.43)
),
1,((-20.41,-5.20)
 .. controls (-20.41,-5.20) and (-20.18,-4.07) .. (-19.96,-4.75)
 .. controls (-19.73,-5.42) and (-17.30,-4.70) .. (-17.30,-5.78)
 .. controls (-17.30,-6.86) and (-20.50,-11.27) .. (-16.09,-11.59)
 .. controls (-11.68,-11.90) and (-11.71,-12.37) .. (-11.27,-13.03)
));
draw_downscrap;
endfig;
beginfig(69);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.54,-11.32)
 .. controls (-7.54,-11.32) and (-8.35,-9.97) .. (-8.08,-8.48)
 .. controls (-7.81,-7.00) and (-8.08,-5.96) .. (-7.99,-5.11)
 .. controls (-7.90,-4.25) and (-6.68,-1.96) .. (-6.23,0.07)
 .. controls (-5.78,2.09) and (-5.15,3.44) .. (-5.69,4.21)
 .. controls (-6.23,4.97) and (-8.57,13.03) .. (-9.38,13.03)
 .. controls (-9.86,13.03) and (-12.62,11.41) .. (-12.44,9.43)
 .. controls (-12.26,7.45) and (-12.62,6.86) .. (-12.49,5.56)
 .. controls (-12.35,4.25) and (-11.45,0.83) .. (-12.80,1.51)
 .. controls (-14.15,2.18) and (-16.67,4.39) .. (-16.67,4.39)
 .. controls (-16.67,4.39) and (-18.11,4.25) .. (-18.16,2.59)
 .. controls (-18.20,0.92) and (-18.02,-0.38) .. (-18.97,-0.25)
 .. controls (-19.91,-0.11) and (-22.66,0.74) .. (-23.24,1.10)
 .. controls (-23.83,1.46) and (-25.04,1.73) .. (-25.99,2.63)
 .. controls (-26.93,3.53) and (-30.58,5.74) .. (-30.58,5.74)
));
ATTR__height := -1;
drawoptions();
l_pit(((-12.26,0.56)
 .. controls (-12.58,0.61) and (-13.21,0.65) .. (-14.87,1.24)
 .. controls (-16.54,1.82) and (-17.08,0.29) .. (-17.08,-0.20)
 .. controls (-17.08,-0.70) and (-18.16,-0.92) .. (-19.60,-1.06)
 .. controls (-21.04,-1.19) and (-20.27,-1.69) .. (-20.72,-3.13)
 .. controls (-21.17,-4.57) and (-18.52,-4.21) .. (-17.48,-4.39)
 .. controls (-16.45,-4.57) and (-16.13,-5.74) .. (-16.22,-6.14)
 .. controls (-16.31,-6.55) and (-16.36,-7.85) .. (-16.90,-9.47)
 .. controls (-17.44,-11.09) and (-11.59,-11.54) .. (-11.59,-11.54)
));
ATTR__height := -1;
drawoptions();
l_pit(((-8.71,-10.10)
 .. controls (-8.93,-9.47) and (-8.89,-6.86) .. (-8.89,-5.87)
 .. controls (-8.89,-4.88) and (-7.49,-0.43) .. (-6.55,0.92)
 .. controls (-5.60,2.27) and (-7.18,4.93) .. (-7.27,5.20)
 .. controls (-7.36,5.47) and (-7.81,7.00) .. (-8.26,8.21)
 .. controls (-8.71,9.43) and (-9.74,9.52) .. (-10.82,9.34)
 .. controls (-11.90,9.16) and (-11.72,6.55) .. (-11.63,6.14)
 .. controls (-11.54,5.74) and (-11.14,2.14) .. (-11.14,2.14)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-34.44,2.54)
 .. controls (-34.44,2.54) and (-32.38,0.61) .. (-31.21,-0.38)
 .. controls (-30.04,-1.37) and (-29.23,-2.77) .. (-29.00,-3.08)
 .. controls (-28.63,-3.61) and (-28.15,-3.98) .. (-28.10,-4.43)
));
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((-35.39,6.41),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((-5.60,-8.93)
 -- (30.62,-8.93)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-20.41,-5.20)
 .. controls (-20.41,-5.20) and (-20.18,-4.07) .. (-19.96,-4.75)
 .. controls (-19.73,-5.42) and (-17.30,-4.70) .. (-17.30,-5.78)
 .. controls (-17.30,-6.86) and (-20.50,-11.27) .. (-16.09,-11.59)
 .. controls (-11.68,-11.90) and (-11.71,-12.37) .. (-11.27,-13.03)
));
endfig;
beginfig(70);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char49 \char50 \char55 \char57 \mainfont{} etex,(-9.16,12.94),0.0,1);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char100 \char117 \ \char81 \char117 \char97 \char114 \char116 \ \char100 \char101 \ \char102 \char105 \char110 \char97 \char108 \char58 \ \char80 \char49 \char54 \mainfont{} etex,(35.39,-8.93),0.0,0);
endfig;
background:=(0.83500,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.83500, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP7@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP7";
beginfig(71);
ATTR__height := -1;
drawoptions();
l_floormeander(((-1.24,-0.05)
 .. controls (-1.24,-0.05) and (-3.44,4.95) .. (-3.62,6.52)
 .. controls (-3.80,8.10) and (-3.44,8.87) .. (-3.13,10.98)
 .. controls (-2.81,13.10) and (-3.01,12.42) .. (-2.18,13.59)
 .. controls (-1.19,14.99) and (-0.83,14.90) .. (-0.43,15.93)
 .. controls (-0.07,16.84) and (0.70,16.56) .. (0.56,17.15)
));
endfig;
beginfig(72);
draw_upscrap(1)(1,((6.55,-17.19)
 .. controls (6.55,-17.19) and (7.67,-15.75) .. (9.11,-15.66)
 .. controls (10.55,-15.57) and (11.78,-16.05) .. (12.49,-13.77)
 .. controls (13.48,-10.57) and (12.53,-11.38) .. (12.44,-9.76)
 .. controls (12.35,-8.10) and (9.20,-5.31) .. (8.98,-4.45)
 .. controls (8.75,-3.60) and (5.56,-2.66) .. (4.88,-3.15)
 .. controls (4.21,-3.65) and (3.85,-1.80) .. (3.62,-1.35)
 .. controls (3.40,-0.90) and (2.50,1.35) .. (1.19,2.43)
 .. controls (-0.11,3.51) and (-0.52,4.64) .. (-0.65,6.30)
 .. controls (-0.79,7.97) and (-0.02,13.37) .. (0.38,13.82)
 .. controls (0.79,14.27) and (1.96,16.38) .. (2.41,16.65)
),
1,((-5.29,17.42)
 .. controls (-4.48,16.65) and (-4.07,14.63) .. (-4.48,13.73)
 .. controls (-4.88,12.83) and (-4.34,9.86) .. (-4.57,8.91)
 .. controls (-4.79,7.96) and (-7.81,6.57) .. (-8.66,4.99)
 .. controls (-9.56,3.35) and (-7.13,4.72) .. (-7.40,0.04)
 .. controls (-7.67,-4.64) and (0.16,-4.23) .. (0.97,-6.39)
 .. controls (1.78,-8.55) and (1.19,-15.89) .. (1.19,-15.89)
));
draw_downscrap;
endfig;
beginfig(73);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.55,-17.19)
 .. controls (6.55,-17.19) and (7.67,-15.75) .. (9.11,-15.66)
 .. controls (10.55,-15.57) and (11.78,-16.05) .. (12.49,-13.77)
 .. controls (13.48,-10.57) and (12.53,-11.38) .. (12.44,-9.76)
 .. controls (12.35,-8.10) and (9.20,-5.31) .. (8.98,-4.45)
 .. controls (8.75,-3.60) and (5.56,-2.66) .. (4.88,-3.15)
 .. controls (4.21,-3.65) and (3.85,-1.80) .. (3.62,-1.35)
 .. controls (3.40,-0.90) and (2.50,1.35) .. (1.19,2.43)
 .. controls (-0.11,3.51) and (-0.52,4.64) .. (-0.65,6.30)
 .. controls (-0.79,7.97) and (-0.02,13.37) .. (0.38,13.82)
 .. controls (0.79,14.27) and (1.96,16.38) .. (2.41,16.65)
));
ATTR__height := -1;
drawoptions();
l_pit(((1.73,-6.44)
 .. controls (2.23,-7.34) and (1.42,-14.85) .. (1.87,-15.44)
 .. controls (2.32,-16.02) and (4.93,-17.42) .. (7.22,-15.75)
 .. controls (9.52,-14.08) and (9.74,-14.85) .. (10.87,-14.49)
 .. controls (11.99,-14.13) and (11.81,-13.09) .. (11.72,-11.83)
 .. controls (11.63,-10.57) and (10.42,-7.74) .. (9.20,-6.30)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.29,17.42)
 .. controls (-4.48,16.65) and (-4.07,14.63) .. (-4.48,13.73)
 .. controls (-4.88,12.83) and (-4.34,9.86) .. (-4.57,8.91)
 .. controls (-4.79,7.96) and (-7.81,6.57) .. (-8.66,4.99)
 .. controls (-9.56,3.35) and (-7.13,4.72) .. (-7.40,0.04)
 .. controls (-7.67,-4.64) and (0.16,-4.23) .. (0.97,-6.39)
 .. controls (1.78,-8.55) and (1.19,-15.89) .. (1.19,-15.89)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((0.56,-8.37)
 -- (-13.48,0.22)
 -- (-13.48,11.29)
));
endfig;
beginfig(74);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char49 \char50 \char57 \char54 \mainfont{} etex,(0.70,3.02),0.0,1);
drawoptions();
p_label.top(btex \thlabel\thnormalsize \thfb\char80 \char49 \char50 \mainfont{} etex,(-13.48,13.36),0.0,0);
endfig;
background:=(0.90250,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.90250, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP6@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP6";
beginfig(75);
ATTR__height := -1;
drawoptions();
l_pit(((-2.29,8.66)
 .. controls (-2.29,8.66) and (0.04,9.06) .. (1.89,10.28)
 .. controls (3.87,11.59) and (4.28,12.53) .. (1.89,13.12)
 .. controls (-1.38,13.92) and (-1.80,14.83) .. (-1.80,14.83)
));
endfig;
beginfig(76);
draw_upscrap(1)(1,((-5.35,2.86)
 .. controls (-5.35,2.86) and (-3.55,7.67) .. (-2.07,8.08)
 .. controls (-0.58,8.48) and (-1.35,7.31) .. (1.08,8.80)
 .. controls (3.51,10.28) and (7.92,12.13) .. (1.22,14.47)
 .. controls (-5.49,16.81) and (-3.06,17.39) .. (-2.57,17.75)
),
1,((-7.92,19.06)
 .. controls (-7.15,14.33) and (-4.95,13.16) .. (-4.77,12.08)
 .. controls (-4.59,11.00) and (-4.68,10.78) .. (-4.68,10.78)
));
draw_downscrap;
endfig;
beginfig(77);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.35,2.86)
 .. controls (-5.35,2.86) and (-3.55,7.67) .. (-2.07,8.08)
 .. controls (-0.58,8.48) and (-1.35,7.31) .. (1.08,8.80)
 .. controls (3.51,10.28) and (7.92,12.13) .. (1.22,14.47)
 .. controls (-5.49,16.81) and (-3.06,17.39) .. (-2.57,17.75)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-1.35,7.63)
 -- (-1.35,5.06)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((1.85,-0.52)
 -- (1.89,-28.87)
));
ATTR__height := -1;
drawoptions();
l_pit(((-4.14,12.49)
 .. controls (-4.05,12.04) and (-3.60,10.82) .. (-3.69,9.61)
 .. controls (-3.78,8.39) and (-2.29,8.66) .. (-2.29,8.66)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-0.94,-4.66)
 -- (7.74,8.48)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((7.74,8.48)
 -- (3.24,30.22)
 -- (1.84,30.08)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-0.94,-4.66)
 -- (-4.09,-3.67)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.92,19.06)
 .. controls (-7.15,14.33) and (-4.95,13.16) .. (-4.77,12.08)
 .. controls (-4.59,11.00) and (-4.68,10.78) .. (-4.68,10.78)
));
endfig;
beginfig(78);
drawoptions();
p_label.bot(btex \thlabel\thnormalsize \thfb\char80 \char49 \char48 \mainfont{} etex,(-1.35,3.76),0.0,0);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char76 \char101 \char115 \ \char112 \char117 \char105 \char116 \char115 \ \char100 \char101 \ \char108 \char97 \ \char84 \char111 \char99 \char99 \char97 \char116 \char97 \mainfont{} etex,(1.98,-30.22),0.0,0);
endfig;
background:=(0.97750,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.97750, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP5@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP5";
beginfig(79);
ATTR__height := -1;
drawoptions();
l_pit(((29.90,0.88)
 .. controls (29.90,0.88) and (28.96,-0.52) .. (28.60,-1.24)
 .. controls (28.24,-1.96) and (26.12,-5.78) .. (26.26,-7.00)
 .. controls (26.40,-8.21) and (27.61,-10.55) .. (28.56,-10.55)
 .. controls (29.50,-10.55) and (31.71,-9.83) .. (32.29,-8.17)
 .. controls (32.88,-6.50) and (33.46,-2.09) .. (33.55,-1.28)
));
endfig;
beginfig(80);
draw_upscrap(1)(1,((35.03,12.89)
 .. controls (31.79,11.68) and (32.96,10.60) .. (32.96,9.16)
 .. controls (32.96,7.72) and (29.27,7.49) .. (26.75,5.96)
 .. controls (25.17,5.00) and (30.22,2.41) .. (29.00,0.52)
 .. controls (27.79,-1.37) and (23.51,-6.86) .. (26.26,-9.88)
 .. controls (29.01,-12.89) and (29.32,-11.72) .. (31.57,-10.46)
 .. controls (33.82,-9.20) and (34.31,0.16) .. (33.82,1.60)
 .. controls (33.32,3.04) and (34.36,4.97) .. (34.36,4.97)
));
draw_downscrap;
endfig;
beginfig(81);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((35.03,12.89)
 .. controls (31.79,11.68) and (32.96,10.60) .. (32.96,9.16)
 .. controls (32.96,7.72) and (29.27,7.49) .. (26.75,5.96)
 .. controls (25.17,5.00) and (30.22,2.41) .. (29.00,0.52)
 .. controls (27.79,-1.37) and (23.51,-6.86) .. (26.26,-9.88)
 .. controls (29.01,-12.89) and (29.32,-11.72) .. (31.57,-10.46)
 .. controls (33.82,-9.20) and (34.31,0.16) .. (33.82,1.60)
 .. controls (33.32,3.04) and (34.36,4.97) .. (34.36,4.97)
));
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((25.72,-11.95),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((24.24,-7.94)
 -- (-26.30,-7.99)
));
endfig;
beginfig(82);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char114 \char101 \char109 \char111 \char110 \char116 \char97 \char110 \char116 \ \thfc\char184 \ \thfb\char101 \char115 \char99 \char97 \char108 \char97 \char100 \char101 \char114 \mainfont{} etex,(-35.03,-7.73),0.0,0);
endfig;
background:=(0.99250,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.99250, 1.00000, 0.25000);
current_scrap := "D35_20160703_SP4@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP4";
beginfig(83);
draw_upscrap(1)(1,((3.06,-11.95)
 .. controls (3.33,-11.27) and (3.24,-10.24) .. (3.87,-9.47)
 .. controls (4.50,-8.71) and (3.33,-3.89) .. (3.10,-3.40)
 .. controls (2.88,-2.90) and (2.02,-0.07) .. (1.53,1.28)
 .. controls (1.04,2.63) and (2.47,5.65) .. (2.70,6.64)
 .. controls (2.92,7.63) and (2.25,9.38) .. (1.53,10.55)
 .. controls (0.81,11.72) and (-0.99,11.63) .. (-1.53,11.45)
 .. controls (-2.07,11.27) and (-3.19,11.95) .. (-3.19,11.95)
),
1,((-4.50,8.71)
 .. controls (-4.50,8.71) and (-2.11,8.30) .. (-1.12,8.53)
 .. controls (-0.13,8.75) and (0.90,7.09) .. (0.90,6.32)
 .. controls (0.90,5.56) and (-0.67,3.35) .. (-0.04,1.64)
 .. controls (0.59,-0.07) and (1.21,-2.32) .. (1.39,-3.44)
 .. controls (1.57,-4.57) and (2.70,-5.29) .. (2.61,-7.09)
 .. controls (2.52,-8.80) and (1.71,-10.82) .. (1.44,-11.68)
));
draw_downscrap;
endfig;
beginfig(84);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.06,-11.95)
 .. controls (3.33,-11.27) and (3.24,-10.24) .. (3.87,-9.47)
 .. controls (4.50,-8.71) and (3.33,-3.89) .. (3.10,-3.40)
 .. controls (2.88,-2.90) and (2.02,-0.07) .. (1.53,1.28)
 .. controls (1.04,2.63) and (2.47,5.65) .. (2.70,6.64)
 .. controls (2.92,7.63) and (2.25,9.38) .. (1.53,10.55)
 .. controls (0.81,11.72) and (-0.99,11.63) .. (-1.53,11.45)
 .. controls (-2.07,11.27) and (-3.19,11.95) .. (-3.19,11.95)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.50,8.71)
 .. controls (-4.50,8.71) and (-2.11,8.30) .. (-1.12,8.53)
 .. controls (-0.13,8.75) and (0.90,7.09) .. (0.90,6.32)
 .. controls (0.90,5.56) and (-0.67,3.35) .. (-0.04,1.64)
 .. controls (0.59,-0.07) and (1.21,-2.32) .. (1.39,-3.44)
 .. controls (1.57,-4.57) and (2.70,-5.29) .. (2.61,-7.09)
 .. controls (2.52,-8.80) and (1.71,-10.82) .. (1.44,-11.68)
));
endfig;
beginfig(85);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char51 \char49 \char56 \mainfont{} etex,(-0.27,2.45),0.0,1);
endfig;
background:=(1.00000,0.97750,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.97750, 0.25000);
current_scrap := "D35_20160703_SP3@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP3";
beginfig(86);
ATTR__height := -1;
drawoptions();
l_floorstep(((12.22,7.36)
 .. controls (12.22,7.36) and (8.30,6.14) .. (7.27,4.52)
));
endfig;
beginfig(87);
draw_upscrap(1)(1,((6.82,6.91)
 .. controls (6.82,6.91) and (7.49,5.51) .. (8.44,4.84)
 .. controls (9.38,4.16) and (11.09,3.31) .. (11.36,2.68)
 .. controls (11.63,2.05) and (12.85,0.47) .. (13.25,0.34)
 .. controls (13.66,0.20) and (14.51,-0.65) .. (15.01,-1.37)
 .. controls (15.50,-2.09) and (16.06,-3.70) .. (16.45,-3.98)
 .. controls (17.65,-4.87) and (19.62,-5.20) .. (19.87,-5.38)
 .. controls (21.85,-6.77) and (21.35,-6.41) .. (22.66,-6.95)
 .. controls (23.96,-7.49) and (25.09,-7.72) .. (26.35,-8.03)
),
1,((27.65,-4.79)
 .. controls (26.57,-3.76) and (19.78,-3.08) .. (18.92,-2.81)
 .. controls (18.18,-2.58) and (16.63,-0.88) .. (15.55,-0.29)
 .. controls (14.47,0.29) and (13.34,2.18) .. (12.94,3.13)
 .. controls (12.53,4.07) and (13.66,4.07) .. (13.43,5.42)
 .. controls (13.21,6.77) and (11.18,6.41) .. (10.64,6.95)
 .. controls (10.10,7.49) and (9.65,8.03) .. (9.65,8.03)
));
draw_downscrap;
endfig;
beginfig(88);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((27.65,-4.79)
 .. controls (26.57,-3.76) and (19.78,-3.08) .. (18.92,-2.81)
 .. controls (18.18,-2.58) and (16.63,-0.88) .. (15.55,-0.29)
 .. controls (14.47,0.29) and (13.34,2.18) .. (12.94,3.13)
 .. controls (12.53,4.07) and (13.66,4.07) .. (13.43,5.42)
 .. controls (13.21,6.77) and (11.18,6.41) .. (10.64,6.95)
 .. controls (10.10,7.49) and (9.65,8.03) .. (9.65,8.03)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.82,6.91)
 .. controls (6.82,6.91) and (7.49,5.51) .. (8.44,4.84)
 .. controls (9.38,4.16) and (11.09,3.31) .. (11.36,2.68)
 .. controls (11.63,2.05) and (12.85,0.47) .. (13.25,0.34)
 .. controls (13.66,0.20) and (14.51,-0.65) .. (15.01,-1.37)
 .. controls (15.50,-2.09) and (16.06,-3.70) .. (16.45,-3.98)
 .. controls (17.65,-4.87) and (19.62,-5.20) .. (19.87,-5.38)
 .. controls (21.85,-6.77) and (21.35,-6.41) .. (22.66,-6.95)
 .. controls (23.96,-7.49) and (25.09,-7.72) .. (26.35,-8.03)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((19.42,-6.41)
 -- (-24.77,-6.41)
));
endfig;
beginfig(89);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char66 \char111 \char121 \char97 \char117 \ \char100 \char117 \ \char109 \char101 \char115 \char115 \char97 \char103 \char101 \char114 \ \char70 \char108 \char111 \char114 \char105 \char97 \char110 \mainfont{} etex,(-27.65,-6.37),0.0,0);
endfig;
background:=(1.00000,0.94000,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.94000, 0.25000);
current_scrap := "D35_20160703_SP2@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP2";
beginfig(90);
ATTR__height := -1;
drawoptions();
l_floorstep(((-13.36,-18.39)
 .. controls (-13.36,-18.39) and (-11.00,-18.73) .. (-8.73,-17.31)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((-13.28,2.53)
 .. controls (-13.28,2.53) and (-20.11,1.72) .. (-20.29,0.42)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((-13.59,-2.91)
 .. controls (-15.32,-2.37) and (-18.67,-3.00) .. (-18.67,-3.14)
));
endfig;
beginfig(91);
draw_upscrap(1)(1,((-7.51,-16.81)
 .. controls (-7.51,-16.81) and (-8.64,-14.83) .. (-8.59,-14.29)
 .. controls (-8.55,-13.75) and (-8.95,-12.76) .. (-8.95,-12.22)
 .. controls (-8.95,-11.68) and (-10.08,-7.63) .. (-10.08,-7.63)
 .. controls (-10.08,-7.63) and (-11.57,-5.92) .. (-12.20,-5.25)
 .. controls (-12.83,-4.57) and (-15.03,-3.95) .. (-15.43,-3.50)
 .. controls (-15.84,-3.05) and (-16.29,-1.79) .. (-16.24,-1.07)
 .. controls (-16.20,-0.35) and (-16.15,-0.26) .. (-16.20,0.87)
 .. controls (-16.25,1.99) and (-16.47,2.85) .. (-16.61,3.34)
 .. controls (-16.74,3.84) and (-17.10,4.74) .. (-16.97,5.41)
 .. controls (-16.83,6.09) and (-17.01,7.66) .. (-17.19,8.02)
 .. controls (-17.37,8.38) and (-17.91,11.17) .. (-17.91,11.17)
 -- (-17.82,12.52)
),
1,((-19.53,12.47)
 -- (-19.08,10.94)
 .. controls (-19.08,10.94) and (-18.77,9.95) .. (-18.77,9.64)
 .. controls (-18.77,9.32) and (-18.36,7.61) .. (-18.32,7.39)
 .. controls (-18.27,7.16) and (-18.00,5.95) .. (-18.13,5.46)
 .. controls (-18.27,4.96) and (-18.63,4.60) .. (-18.36,3.70)
 .. controls (-18.09,2.80) and (-17.86,1.90) .. (-17.82,1.36)
 .. controls (-17.77,0.82) and (-17.68,-0.57) .. (-17.68,-0.98)
 .. controls (-17.68,-1.38) and (-17.32,-2.96) .. (-17.37,-3.32)
 .. controls (-17.41,-3.68) and (-19.26,-4.26) .. (-19.26,-4.26)
 -- (-20.83,-5.29)
),
1,((-18.31,-12.45)
 .. controls (-18.31,-12.45) and (-15.93,-11.50) .. (-14.62,-12.67)
 .. controls (-13.32,-13.84) and (-12.24,-16.23) .. (-11.92,-17.08)
 .. controls (-11.61,-17.94) and (-10.93,-19.96) .. (-10.75,-20.32)
 .. controls (-10.57,-20.68) and (-9.94,-22.48) .. (-9.81,-24.10)
 .. controls (-9.67,-25.72) and (-8.19,-29.28) .. (-8.19,-29.28)
),
1,((-5.35,-28.15)
 .. controls (-5.35,-28.15) and (-6.57,-25.23) .. (-7.06,-23.70)
 .. controls (-7.56,-22.17) and (-9.18,-20.41) .. (-9.09,-19.33)
 .. controls (-9.00,-18.25) and (-10.26,-16.59) .. (-9.58,-16.59)
 .. controls (-8.91,-16.59) and (-8.32,-16.99) .. (-8.32,-16.99)
));
draw_downscrap;
endfig;
beginfig(92);
ATTR__height := -1;
drawoptions();
l_rockedge(((-6.43,-16.23)
 -- (-4.68,-14.25)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.35,-28.15)
 .. controls (-5.35,-28.15) and (-6.57,-25.23) .. (-7.06,-23.70)
 .. controls (-7.56,-22.17) and (-9.18,-20.41) .. (-9.09,-19.33)
 .. controls (-9.00,-18.25) and (-10.26,-16.59) .. (-9.58,-16.59)
 .. controls (-8.91,-16.59) and (-8.32,-16.99) .. (-8.32,-16.99)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.51,-16.81)
 .. controls (-7.51,-16.81) and (-8.64,-14.83) .. (-8.59,-14.29)
 .. controls (-8.55,-13.75) and (-8.95,-12.76) .. (-8.95,-12.22)
 .. controls (-8.95,-11.68) and (-10.08,-7.63) .. (-10.08,-7.63)
 .. controls (-10.08,-7.63) and (-11.57,-5.92) .. (-12.20,-5.25)
 .. controls (-12.83,-4.57) and (-15.03,-3.95) .. (-15.43,-3.50)
 .. controls (-15.84,-3.05) and (-16.29,-1.79) .. (-16.24,-1.07)
 .. controls (-16.20,-0.35) and (-16.15,-0.26) .. (-16.20,0.87)
 .. controls (-16.25,1.99) and (-16.47,2.85) .. (-16.61,3.34)
 .. controls (-16.74,3.84) and (-17.10,4.74) .. (-16.97,5.41)
 .. controls (-16.83,6.09) and (-17.01,7.66) .. (-17.19,8.02)
 .. controls (-17.37,8.38) and (-17.91,11.17) .. (-17.91,11.17)
 -- (-17.82,12.52)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-19.53,12.47)
 -- (-19.08,10.94)
 .. controls (-19.08,10.94) and (-18.77,9.95) .. (-18.77,9.64)
 .. controls (-18.77,9.32) and (-18.36,7.61) .. (-18.32,7.39)
 .. controls (-18.27,7.16) and (-18.00,5.95) .. (-18.13,5.46)
 .. controls (-18.27,4.96) and (-18.63,4.60) .. (-18.36,3.70)
 .. controls (-18.09,2.80) and (-17.86,1.90) .. (-17.82,1.36)
 .. controls (-17.77,0.82) and (-17.68,-0.57) .. (-17.68,-0.98)
 .. controls (-17.68,-1.38) and (-17.32,-2.96) .. (-17.37,-3.32)
 .. controls (-17.41,-3.68) and (-19.26,-4.26) .. (-19.26,-4.26)
 -- (-20.83,-5.29)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-4.68,-14.25)
 -- (-4.69,7.39)
));
drawoptions();
p_airdraught_summer((-20.41,19.49),196.7,1.00,(0,0));
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((-22.23,27.27),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-18.31,-12.45)
 .. controls (-18.31,-12.45) and (-15.93,-11.50) .. (-14.62,-12.67)
 .. controls (-13.32,-13.84) and (-12.24,-16.23) .. (-11.92,-17.08)
 .. controls (-11.61,-17.94) and (-10.93,-19.96) .. (-10.75,-20.32)
 .. controls (-10.57,-20.68) and (-9.94,-22.48) .. (-9.81,-24.10)
 .. controls (-9.67,-25.72) and (-8.19,-29.28) .. (-8.19,-29.28)
));
drawoptions();
p_airdraught_summer((-4.14,-22.42),31.7,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((-18.36,13.19)
 -- (-1.81,29.25)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-1.81,29.25)
 -- (20.32,29.26)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((5.93,18.41)
 -- (-4.69,7.39)
));
endfig;
beginfig(93);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfc\char233 \thfb\char116 \char114 \char111 \char105 \char116 \char117 \char114 \char101 \ \thfc\char184 \ \thfb\char102 \char111 \char114 \char99 \char101 \char114 \mainfont{} etex,(7.34,18.39),0.0,0);
drawoptions();
p_label.llft(btex \thaltitude \thfb\char49 \char51 \char50 \char52 \mainfont{} etex,(-9.94,-23.61),0.0,1);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char105 \char109 \char112 \mainfont{} etex,(22.23,29.28),0.0,0);
endfig;
background:=(1.00000,0.85750,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.85750, 0.25000);
current_scrap := "D35_20160703_SP1@D35_20160703.D35projet";
ATTR__scrap := "D35_20160703_SP1";
beginfig(94);
draw_upscrap(1)(1,((12.36,2.79)
 .. controls (12.36,2.79) and (12.89,2.75) .. (12.82,2.34)
 .. controls (12.74,1.93) and (12.61,0.92) .. (12.37,0.86)
 .. controls (12.14,0.80) and (10.95,-0.81) .. (10.37,-1.04)
 .. controls (9.84,-1.25) and (9.29,-1.17) .. (9.13,-2.12)
 .. controls (8.98,-3.06) and (8.86,-4.11) .. (9.57,-4.65)
 .. controls (10.29,-5.19) and (10.41,-6.44) .. (12.11,-6.75)
 .. controls (13.78,-7.06) and (15.46,-7.01) .. (16.73,-6.61)
),
1,((14.21,0.55)
 .. controls (14.21,0.55) and (13.14,-0.91) .. (13.13,-0.09)
 .. controls (13.12,0.72) and (13.51,1.04) .. (13.79,1.49)
 .. controls (14.08,1.94) and (15.57,3.86) .. (14.82,5.08)
 .. controls (13.99,6.43) and (14.16,7.06) .. (14.16,7.06)
));
draw_downscrap;
endfig;
beginfig(95);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((14.21,0.55)
 .. controls (14.21,0.55) and (13.14,-0.91) .. (13.13,-0.09)
 .. controls (13.12,0.72) and (13.51,1.04) .. (13.79,1.49)
 .. controls (14.08,1.94) and (15.57,3.86) .. (14.82,5.08)
 .. controls (13.99,6.43) and (14.16,7.06) .. (14.16,7.06)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((12.36,2.79)
 .. controls (12.36,2.79) and (12.89,2.75) .. (12.82,2.34)
 .. controls (12.74,1.93) and (12.61,0.92) .. (12.37,0.86)
 .. controls (12.14,0.80) and (10.95,-0.81) .. (10.37,-1.04)
 .. controls (9.84,-1.25) and (9.29,-1.17) .. (9.13,-2.12)
 .. controls (8.98,-3.06) and (8.86,-4.11) .. (9.57,-4.65)
 .. controls (10.29,-5.19) and (10.41,-6.44) .. (12.11,-6.75)
 .. controls (13.78,-7.06) and (15.46,-7.01) .. (16.73,-6.61)
));
ATTR__height := -1;
drawoptions();
l_pit(((18.73,1.47)
 .. controls (18.73,1.47) and (17.57,1.55) .. (16.43,1.00)
 .. controls (15.27,0.45) and (15.42,-0.12) .. (14.64,-0.45)
 .. controls (13.92,-0.75) and (12.10,-1.27) .. (11.34,-1.35)
 .. controls (10.57,-1.44) and (9.28,-1.77) .. (9.62,-2.70)
 .. controls (9.96,-3.67) and (10.06,-5.00) .. (11.14,-5.50)
 .. controls (12.20,-5.99) and (15.98,-6.33) .. (16.65,-6.02)
 .. controls (17.34,-5.70) and (18.41,-5.66) .. (18.60,-5.62)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((7.85,-4.79)
 -- (-17.19,-4.78)
));
endfig;
beginfig(96);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char100 \char101 \ \char108 \char97 \ \char103 \char97 \char103 \char110 \char101 \char58 \ \char80 \char49 \char55 \mainfont{} etex,(-18.73,-4.78),0.0,0);
endfig;
background:=(0.25000,1.00000,0.29500);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.29500);
current_scrap := "D35_20160802_SP8@d35___020816.D35projet";
ATTR__scrap := "D35_20160802_SP8";
beginfig(97);
ATTR__survey := "d35___020816.D35projet";
ATTR__height := -1;
drawoptions();
l_pit(((-0.68,-3.81)
 .. controls (-0.68,-3.81) and (1.92,-3.70) .. (1.98,-1.41)
 .. controls (2.00,-0.55) and (1.10,-0.48) .. (0.54,0.21)
 .. controls (-0.02,0.91) and (-3.92,1.50) .. (-5.13,1.59)
 .. controls (-6.35,1.68) and (-6.86,2.01) .. (-8.24,1.61)
 .. controls (-9.61,1.20) and (-8.37,0.28) .. (-7.90,-0.33)
 .. controls (-7.43,-0.93) and (-6.14,-0.89) .. (-4.55,-2.17)
 .. controls (-2.95,-3.45) and (-0.68,-3.81) .. cycle
));
endfig;
beginfig(98);
draw_upscrap(1)(1,((23.90,-5.64)
 .. controls (23.90,-5.64) and (21.38,-4.06) .. (19.44,-3.75)
 .. controls (17.51,-3.43) and (15.89,-3.79) .. (14.31,-3.66)
 .. controls (12.74,-3.52) and (11.75,-3.52) .. (10.31,-3.57)
 .. controls (8.02,-3.64) and (7.79,-3.88) .. (7.43,-3.79)
 .. controls (7.07,-3.70) and (6.35,-4.15) .. (4.50,-3.39)
),
1,((4.50,-3.39)
 .. controls (4.50,-3.39) and (3.33,-3.16) .. (2.84,-1.72)
 .. controls (2.34,-0.28) and (2.12,-1.27) .. (1.49,0.08)
 .. controls (0.86,1.43) and (-0.32,0.98) .. (-1.08,1.47)
 .. controls (-1.85,1.97) and (-5.18,2.10) .. (-5.85,2.46)
 .. controls (-6.53,2.82) and (-7.38,3.16) .. (-8.06,2.96)
),
1,reverse ((-8.51,-0.73)
 .. controls (-8.51,-0.73) and (-11.86,1.34) .. (-8.06,2.96)
),
1,((-8.51,-0.73)
 .. controls (-8.51,-0.73) and (-5.85,-2.08) .. (-4.77,-2.67)
 .. controls (-3.69,-3.25) and (-2.34,-4.60) .. (-1.04,-4.33)
 .. controls (0.27,-4.06) and (2.34,-3.70) .. (2.34,-3.70)
),
1,((2.34,-3.70)
 .. controls (2.34,-3.70) and (4.14,-3.75) .. (5.13,-4.56)
 .. controls (6.12,-5.37) and (7.25,-5.95) .. (8.10,-6.09)
 .. controls (8.96,-6.22) and (15.98,-7.03) .. (17.64,-7.44)
 .. controls (19.31,-7.84) and (19.62,-8.61) .. (19.89,-9.55)
));
draw_downscrap;
endfig;
beginfig(99);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((23.90,-5.64)
 .. controls (23.90,-5.64) and (21.38,-4.06) .. (19.44,-3.75)
 .. controls (17.51,-3.43) and (15.89,-3.79) .. (14.31,-3.66)
 .. controls (12.74,-3.52) and (11.75,-3.52) .. (10.31,-3.57)
 .. controls (8.02,-3.64) and (7.79,-3.88) .. (7.43,-3.79)
 .. controls (7.07,-3.70) and (6.35,-4.15) .. (4.50,-3.39)
));
drawoptions();
p_airdraught_summer((-5.78,-6.94),233.2,1.00,(-1,-1));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-8.51,-0.73)
 .. controls (-8.51,-0.73) and (-11.86,1.34) .. (-8.06,2.96)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.50,-3.39)
 .. controls (4.50,-3.39) and (3.33,-3.16) .. (2.84,-1.72)
 .. controls (2.34,-0.28) and (2.12,-1.27) .. (1.49,0.08)
 .. controls (0.86,1.43) and (-0.32,0.98) .. (-1.08,1.47)
 .. controls (-1.85,1.97) and (-5.18,2.10) .. (-5.85,2.46)
 .. controls (-6.53,2.82) and (-7.38,3.16) .. (-8.06,2.96)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((3.87,-4.42)
 -- (-0.02,-8.54)
 -- (-23.96,-8.54)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-0.67,2.31)
 -- (6.48,9.55)
 -- (23.76,9.55)
));
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((-4.59,4.06),0.0,0.50,(0,1));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-8.51,-0.73)
 .. controls (-8.51,-0.73) and (-5.85,-2.08) .. (-4.77,-2.67)
 .. controls (-3.69,-3.25) and (-2.34,-4.60) .. (-1.04,-4.33)
 .. controls (0.27,-4.06) and (2.34,-3.70) .. (2.34,-3.70)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2.34,-3.70)
 .. controls (2.34,-3.70) and (4.14,-3.75) .. (5.13,-4.56)
 .. controls (6.12,-5.37) and (7.25,-5.95) .. (8.10,-6.09)
 .. controls (8.96,-6.22) and (15.98,-7.03) .. (17.64,-7.44)
 .. controls (19.31,-7.84) and (19.62,-8.61) .. (19.89,-9.55)
));
endfig;
beginfig(100);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char50 \char48 \char51 \mainfont{} etex,(-9.92,1.23),0.0,1);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char49 \char50 \char48 \char53 \mainfont{} etex,(21.44,-4.35),0.0,1);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char50 \ \char116 \char105 \char114 \char115 \ \char101 \char116 \ \fixaccent{24}\char99 \char97 \ \char112 \char97 \char115 \char115 \char101 \mainfont{} etex,(-25.36,-8.61),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char49 \char48 \ \thfc\char184 \ \thfb\char100 \char101 \char115 \char99 \char101 \char110 \char100 \char114 \char101 \mainfont{} etex,(25.36,9.55),0.0,0);
endfig;
background:=(0.25000,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.25000);
current_scrap := "D35_20160802_SP7@d35___020816.D35projet";
ATTR__scrap := "D35_20160802_SP7";
beginfig(101);
ATTR__height := -1;
drawoptions();
l_pit(((-6.54,1.98)
 .. controls (-6.54,1.98) and (-3.36,-3.06) .. (0.03,2.36)
));
endfig;
beginfig(102);
draw_upscrap(1)(1,((-4.35,2.43)
 .. controls (-4.08,1.85) and (-3.63,0.41) .. (-3.54,-0.63)
 .. controls (-3.45,-1.66) and (-2.55,-2.11) .. (-1.56,-2.74)
 .. controls (-0.57,-3.37) and (0.06,-3.64) .. (1.63,-4.50)
 .. controls (3.21,-5.35) and (3.34,-6.34) .. (3.34,-6.34)
),
1,((6.54,-5.44)
 .. controls (6.54,-5.44) and (5.14,-4.86) .. (4.06,-4.18)
 .. controls (2.98,-3.51) and (1.68,-3.06) .. (0.87,-2.11)
 .. controls (0.06,-1.17) and (-1.20,0.09) .. (-1.34,0.86)
 .. controls (-1.47,1.62) and (-2.19,2.66) .. (-2.15,3.56)
 .. controls (-2.10,4.45) and (-1.65,4.77) .. (-0.98,4.68)
 .. controls (-0.30,4.59) and (1.05,4.42) .. (1.68,4.68)
),
1,((1.68,4.68)
 .. controls (1.60,5.61) and (0.37,5.76) .. (-0.35,6.34)
));
draw_downscrap;
endfig;
beginfig(103);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.35,2.43)
 .. controls (-4.08,1.85) and (-3.63,0.41) .. (-3.54,-0.63)
 .. controls (-3.45,-1.66) and (-2.55,-2.11) .. (-1.56,-2.74)
 .. controls (-0.57,-3.37) and (0.06,-3.64) .. (1.63,-4.50)
 .. controls (3.21,-5.35) and (3.34,-6.34) .. (3.34,-6.34)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.54,-5.44)
 .. controls (6.54,-5.44) and (5.14,-4.86) .. (4.06,-4.18)
 .. controls (2.98,-3.51) and (1.68,-3.06) .. (0.87,-2.11)
 .. controls (0.06,-1.17) and (-1.20,0.09) .. (-1.34,0.86)
 .. controls (-1.47,1.62) and (-2.19,2.66) .. (-2.15,3.56)
 .. controls (-2.10,4.45) and (-1.65,4.77) .. (-0.98,4.68)
 .. controls (-0.30,4.59) and (1.05,4.42) .. (1.68,4.68)
));
drawoptions();
p_moonmilk((2.71,-2.65),328.2,1.00,(1,1));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1.68,4.68)
 .. controls (1.60,5.61) and (0.37,5.76) .. (-0.35,6.34)
));
endfig;
background:=(0.25000,1.00000,0.29500);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.29500);
current_scrap := "D35_20160802_SP5@d35___020816.D35projet";
ATTR__scrap := "D35_20160802_SP5";
beginfig(104);
draw_upscrap(1)(1,((-2.41,-0.41)
 .. controls (-2.50,-0.05) and (-3.35,-0.63) .. (-3.35,-0.63)
 .. controls (-3.35,-0.63) and (-3.96,-0.56) .. (-4.64,-0.65)
 .. controls (-5.31,-0.74) and (-5.24,-1.08) .. (-5.45,-1.01)
 .. controls (-5.65,-0.95) and (-5.94,-1.40) .. (-6.59,-1.37)
 .. controls (-7.25,-1.35) and (-8.71,-1.37) .. (-9.16,-1.46)
 .. controls (-9.61,-1.55) and (-10.24,-1.63) .. (-10.96,-1.94)
),
1,((-10.96,-1.94)
 .. controls (-10.96,-1.94) and (-12.33,-2.05) .. (-12.51,-1.85)
 .. controls (-12.69,-1.64) and (-14.09,-2.03) .. (-14.47,-1.69)
 .. controls (-14.85,-1.35) and (-15.41,-1.91) .. (-15.55,-1.85)
 .. controls (-15.68,-1.78) and (-16.85,-1.94) .. (-17.44,-1.67)
),
1,reverse ((-10.80,-4.66)
 .. controls (-10.80,-4.66) and (-11.52,-4.50) .. (-11.72,-3.80)
 .. controls (-11.93,-3.11) and (-11.86,-3.13) .. (-12.40,-2.90)
 .. controls (-12.94,-2.68) and (-13.14,-3.11) .. (-13.50,-2.88)
 .. controls (-13.86,-2.66) and (-14.67,-2.41) .. (-15.19,-2.54)
 .. controls (-15.71,-2.68) and (-16.43,-3.38) .. (-16.76,-2.90)
 .. controls (-17.10,-2.43) and (-17.69,-2.59) .. (-17.71,-2.41)
),
1,((-10.80,-4.66)
 .. controls (-10.37,-5.31) and (-5.74,-3.06) .. (-5.02,-2.99)
 .. controls (-4.30,-2.93) and (-3.62,-3.11) .. (-3.62,-3.11)
),
1,((-4.07,-1.69)
 .. controls (-4.07,-1.69) and (-3.40,-1.51) .. (-3.15,-1.24)
 .. controls (-2.90,-0.97) and (-2.84,-1.28) .. (-2.57,-1.10)
));
draw_downscrap;
endfig;
beginfig(105);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-10.80,-4.66)
 .. controls (-10.37,-5.31) and (-5.74,-3.06) .. (-5.02,-2.99)
 .. controls (-4.30,-2.93) and (-3.62,-3.11) .. (-3.62,-3.11)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-10.80,-4.66)
 .. controls (-10.80,-4.66) and (-11.52,-4.50) .. (-11.72,-3.80)
 .. controls (-11.93,-3.11) and (-11.86,-3.13) .. (-12.40,-2.90)
 .. controls (-12.94,-2.68) and (-13.14,-3.11) .. (-13.50,-2.88)
 .. controls (-13.86,-2.66) and (-14.67,-2.41) .. (-15.19,-2.54)
 .. controls (-15.71,-2.68) and (-16.43,-3.38) .. (-16.76,-2.90)
 .. controls (-17.10,-2.43) and (-17.69,-2.59) .. (-17.71,-2.41)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2.41,-0.41)
 .. controls (-2.50,-0.05) and (-3.35,-0.63) .. (-3.35,-0.63)
 .. controls (-3.35,-0.63) and (-3.96,-0.56) .. (-4.64,-0.65)
 .. controls (-5.31,-0.74) and (-5.24,-1.08) .. (-5.45,-1.01)
 .. controls (-5.65,-0.95) and (-5.94,-1.40) .. (-6.59,-1.37)
 .. controls (-7.25,-1.35) and (-8.71,-1.37) .. (-9.16,-1.46)
 .. controls (-9.61,-1.55) and (-10.24,-1.63) .. (-10.96,-1.94)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.07,-1.69)
 .. controls (-4.07,-1.69) and (-3.40,-1.51) .. (-3.15,-1.24)
 .. controls (-2.90,-0.97) and (-2.84,-1.28) .. (-2.57,-1.10)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-10.96,-1.94)
 .. controls (-10.96,-1.94) and (-12.33,-2.05) .. (-12.51,-1.85)
 .. controls (-12.69,-1.64) and (-14.09,-2.03) .. (-14.47,-1.69)
 .. controls (-14.85,-1.35) and (-15.41,-1.91) .. (-15.55,-1.85)
 .. controls (-15.68,-1.78) and (-16.85,-1.94) .. (-17.44,-1.67)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-1.33,-0.29)
 -- (4.03,5.31)
 -- (15.64,5.31)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-9.23,-0.63)
 -- (-3.64,5.29)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((4.03,5.31)
 -- (-3.64,5.29)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-9.23,-0.63)
 -- (-17.21,-1.33)
));
endfig;
beginfig(106);
drawoptions();
p_label.top(btex \thaltitude \thtinysize \thfb\char49 \char50 \char48 \char53 \mainfont{} etex,(-6.77,-0.63),45.1,1);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char105 \char109 \char112 \mainfont{} etex,(17.71,5.22),0.0,0);
endfig;
background:=(0.25000,1.00000,0.26500);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.26500);
current_scrap := "D35_20160802_SP4@d35___020816.D35projet";
ATTR__scrap := "D35_20160802_SP4";
beginfig(107);
draw_upscrap(1)(1,((-10.94,-11.70)
 .. controls (-10.94,-11.70) and (-9.50,-11.74) .. (-8.66,-11.81)
 .. controls (-7.83,-11.88) and (-7.04,-12.17) .. (-6.46,-11.95)
 .. controls (-5.87,-11.72) and (-5.56,-10.80) .. (-5.65,-10.37)
 .. controls (-5.74,-9.94) and (-7.47,-9.40) .. (-7.88,-9.27)
 .. controls (-8.28,-9.13) and (-9.36,-8.89) .. (-9.92,-8.82)
 .. controls (-10.49,-8.75) and (-11.79,-8.57) .. (-11.79,-8.57)
));
draw_downscrap;
endfig;
beginfig(108);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-10.94,-11.70)
 .. controls (-10.94,-11.70) and (-9.50,-11.74) .. (-8.66,-11.81)
 .. controls (-7.83,-11.88) and (-7.04,-12.17) .. (-6.46,-11.95)
 .. controls (-5.87,-11.72) and (-5.56,-10.80) .. (-5.65,-10.37)
 .. controls (-5.74,-9.94) and (-7.47,-9.40) .. (-7.88,-9.27)
 .. controls (-8.28,-9.13) and (-9.36,-8.89) .. (-9.92,-8.82)
 .. controls (-10.49,-8.75) and (-11.79,-8.57) .. (-11.79,-8.57)
));
drawoptions();
p_airdraught_summer((-5.90,-13.45),104.4,1.00,(0,-1));
ATTR__height := -1;
drawoptions();
l_rockedge(((-5.04,-15.39)
 -- (-0.54,-21.33)
 -- (7.87,-21.33)
));
endfig;
beginfig(109);
ATTR__height := -1;
drawoptions();
l_label(btex \thhugesize \thfb\char82 {}\thfc\char233 {}\thfb\char115 {}\char101 {}\char97 {}\char117 {}\ \char100 {}\char101 {}\ \char108 {}\char97 {}\ \char112 {}\char101 {}\char117 {}\char114 {}\mainfont{} etex,((-42.29,21.33)
 .. controls (-42.29,21.33) and (-11.95,19.21) .. (-4.41,16.74)
 .. controls (12.60,11.16) and (40.90,10.90) .. (42.29,10.70)
));
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char49 \char48 \char48 \ \char108 \char112 \char115 \ \char48 \char50 \char47 \char48 \char56 \char47 \char49 \char54 \ \char49 \char57 \char58 \char48 \char48 \mainfont{} etex,(9.22,-21.28),0.0,0);
endfig;
background:=(0.28750,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.28750, 1.00000, 0.25000);
current_scrap := "D35_20160802_SP6@d35___020816.D35projet";
ATTR__scrap := "D35_20160802_SP6";
beginfig(110);
ATTR__height := -1;
drawoptions();
l_pit(((-15.63,-7.89)
 .. controls (-15.63,-7.89) and (-14.46,-9.03) .. (-11.89,-6.36)
));
endfig;
beginfig(111);
draw_upscrap(1)(1,((-15.36,-9.37)
 .. controls (-15.36,-9.37) and (-15.94,-9.28) .. (-15.22,-8.02)
 .. controls (-14.50,-6.76) and (-14.86,-3.52) .. (-14.95,-2.67)
 .. controls (-15.04,-1.81) and (-15.13,-1.95) .. (-15.99,-1.59)
 .. controls (-16.84,-1.23) and (-17.34,-1.14) .. (-17.61,-0.37)
 .. controls (-17.88,0.39) and (-18.24,2.19) .. (-18.69,3.00)
),
1,reverse ((-9.10,1.52)
 .. controls (-9.10,1.52) and (-12.39,1.92) .. (-13.02,2.37)
 .. controls (-13.65,2.82) and (-14.19,3.14) .. (-15.49,3.90)
),
1,reverse ((-12.30,-6.81)
 .. controls (-12.79,-5.88) and (-12.70,-5.23) .. (-11.89,-4.33)
 .. controls (-11.08,-3.43) and (-11.53,-2.13) .. (-10.90,-1.00)
 .. controls (-10.27,0.12) and (-10.00,1.38) .. (-9.10,1.52)
),
1,reverse ((-12.70,-8.65)
 .. controls (-12.70,-8.65) and (-12.68,-8.65) .. (-12.50,-7.62)
));
draw_downscrap;
endfig;
beginfig(112);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-12.30,-6.81)
 .. controls (-12.79,-5.88) and (-12.70,-5.23) .. (-11.89,-4.33)
 .. controls (-11.08,-3.43) and (-11.53,-2.13) .. (-10.90,-1.00)
 .. controls (-10.27,0.12) and (-10.00,1.38) .. (-9.10,1.52)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-12.70,-8.65)
 .. controls (-12.70,-8.65) and (-12.68,-8.65) .. (-12.50,-7.62)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.10,1.52)
 .. controls (-9.10,1.52) and (-12.39,1.92) .. (-13.02,2.37)
 .. controls (-13.65,2.82) and (-14.19,3.14) .. (-15.49,3.90)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-11.46,2.33)
 -- (-4.11,9.37)
 -- (16.39,9.35)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-15.36,-9.37)
 .. controls (-15.36,-9.37) and (-15.94,-9.28) .. (-15.22,-8.02)
 .. controls (-14.50,-6.76) and (-14.86,-3.52) .. (-14.95,-2.67)
 .. controls (-15.04,-1.81) and (-15.13,-1.95) .. (-15.99,-1.59)
 .. controls (-16.84,-1.23) and (-17.34,-1.14) .. (-17.61,-0.37)
 .. controls (-17.88,0.39) and (-18.24,2.19) .. (-18.69,3.00)
));
endfig;
beginfig(113);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char79 \char117 \char97 \char114 \char107 \char97 \char116 \char122 \char101 \char108 \char115 \char99 \char104 \char97 \char119 \char102 \char58 \ \char80 \char57 \mainfont{} etex,(18.69,9.35),0.0,0);
endfig;
background:=(0.25750,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.25750, 1.00000, 0.25000);
current_scrap := "D35_20160802_SP3@d35___020816.D35projet";
ATTR__scrap := "D35_20160802_SP3";
beginfig(114);
draw_upscrap(1)(1,((4.71,1.98)
 .. controls (4.71,1.98) and (3.70,1.98) .. (3.48,1.89)
 .. controls (3.25,1.80) and (1.47,1.57) .. (0.48,1.44)
 .. controls (-0.51,1.31) and (-1.68,0.59) .. (-2.04,0.68)
 .. controls (-2.40,0.77) and (-2.31,0.95) .. (-3.30,0.81)
 .. controls (-4.29,0.68) and (-4.92,0.81) .. (-4.92,0.81)
),
1,((-5.12,0.00)
 .. controls (-4.80,-0.45) and (-4.17,-1.62) .. (-4.17,-1.62)
),
1,((3.14,-1.98)
 .. controls (3.14,-1.98) and (3.72,-1.75) .. (3.95,-1.12)
 .. controls (4.17,-0.49) and (3.72,-0.09) .. (3.95,0.18)
 .. controls (4.17,0.45) and (5.12,0.27) .. (5.12,0.27)
));
draw_downscrap;
endfig;
beginfig(115);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.12,0.00)
 .. controls (-4.80,-0.45) and (-4.17,-1.62) .. (-4.17,-1.62)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.14,-1.98)
 .. controls (3.14,-1.98) and (3.72,-1.75) .. (3.95,-1.12)
 .. controls (4.17,-0.49) and (3.72,-0.09) .. (3.95,0.18)
 .. controls (4.17,0.45) and (5.12,0.27) .. (5.12,0.27)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.71,1.98)
 .. controls (4.71,1.98) and (3.70,1.98) .. (3.48,1.89)
 .. controls (3.25,1.80) and (1.47,1.57) .. (0.48,1.44)
 .. controls (-0.51,1.31) and (-1.68,0.59) .. (-2.04,0.68)
 .. controls (-2.40,0.77) and (-2.31,0.95) .. (-3.30,0.81)
 .. controls (-4.29,0.68) and (-4.92,0.81) .. (-4.92,0.81)
));
endfig;
background:=(0.32500,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.32500, 1.00000, 0.25000);
current_scrap := "D35_20160802_SP2@d35___020816.D35projet";
ATTR__scrap := "D35_20160802_SP2";
beginfig(116);
draw_upscrap(1)(1,((8.03,-1.64)
 .. controls (8.03,-1.64) and (8.30,-1.28) .. (8.26,-0.11)
 .. controls (8.21,1.06) and (8.62,1.10) .. (8.21,2.41)
 .. controls (7.81,3.71) and (8.30,4.75) .. (8.12,5.47)
 .. controls (7.94,6.19) and (7.09,6.59) .. (6.86,6.77)
 .. controls (6.64,6.95) and (5.51,8.53) .. (6.05,10.33)
 .. controls (6.59,12.13) and (7.99,10.69) .. (9.11,11.23)
),
1,((1.80,11.59)
 .. controls (2.21,10.82) and (2.12,10.30) .. (1.80,10.04)
 .. controls (0.95,9.31) and (1.06,10.60) .. (0.70,11.00)
 .. controls (0.34,11.41) and (0.65,12.17) .. (0.65,12.17)
),
1,((-2.00,11.45)
 .. controls (-1.82,10.91) and (-1.64,11.18) .. (-0.88,10.55)
 .. controls (-0.11,9.92) and (-0.61,10.06) .. (-0.29,9.29)
 .. controls (0.02,8.53) and (0.65,8.26) .. (0.97,7.58)
 .. controls (1.28,6.91) and (1.19,6.37) .. (0.65,5.87)
 .. controls (0.11,5.38) and (-0.34,5.47) .. (-0.34,5.47)
));
draw_downscrap;
endfig;
beginfig(117);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((8.03,-1.64)
 .. controls (8.03,-1.64) and (8.30,-1.28) .. (8.26,-0.11)
 .. controls (8.21,1.06) and (8.62,1.10) .. (8.21,2.41)
 .. controls (7.81,3.71) and (8.30,4.75) .. (8.12,5.47)
 .. controls (7.94,6.19) and (7.09,6.59) .. (6.86,6.77)
 .. controls (6.64,6.95) and (5.51,8.53) .. (6.05,10.33)
 .. controls (6.59,12.13) and (7.99,10.69) .. (9.11,11.23)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2.00,11.45)
 .. controls (-1.82,10.91) and (-1.64,11.18) .. (-0.88,10.55)
 .. controls (-0.11,9.92) and (-0.61,10.06) .. (-0.29,9.29)
 .. controls (0.02,8.53) and (0.65,8.26) .. (0.97,7.58)
 .. controls (1.28,6.91) and (1.19,6.37) .. (0.65,5.87)
 .. controls (0.11,5.38) and (-0.34,5.47) .. (-0.34,5.47)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1.80,11.59)
 .. controls (2.21,10.82) and (2.12,10.30) .. (1.80,10.04)
 .. controls (0.95,9.31) and (1.06,10.60) .. (0.70,11.00)
 .. controls (0.34,11.41) and (0.65,12.17) .. (0.65,12.17)
));
endfig;
beginfig(118);
drawoptions();
p_label.llft(btex \thaltitude \thfb\char49 \char50 \char50 \char50 \mainfont{} etex,(-9.11,-12.17),0.0,1);
endfig;
background:=(0.44500,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.44500, 1.00000, 0.25000);
current_scrap := "D35_20160802_SP1@d35___020816.D35projet";
ATTR__scrap := "D35_20160802_SP1";
beginfig(119);
draw_upscrap(1)(1,((-15.08,-13.24)
 .. controls (-15.08,-13.24) and (-13.27,-14.42) .. (-11.57,-14.42)
 .. controls (-9.85,-14.43) and (-8.31,-15.35) .. (-7.23,-14.99)
 .. controls (-6.15,-14.63) and (-4.07,-15.64) .. (-3.36,-14.01)
 .. controls (-2.65,-12.38) and (-5.37,-5.85) .. (-4.69,-3.56)
 .. controls (-4.00,-1.24) and (-3.24,-0.48) .. (-2.67,1.27)
),
1,((-11.04,8.38)
 .. controls (-11.92,8.02) and (-13.55,8.17) .. (-13.86,7.58)
 .. controls (-14.18,6.96) and (-15.36,6.05) .. (-15.63,5.40)
 .. controls (-15.90,4.76) and (-16.03,4.54) .. (-17.44,3.01)
),
1,reverse ((-20.70,-5.81)
 .. controls (-20.70,-5.81) and (-21.27,-0.14) .. (-19.69,1.55)
),
1,((-20.70,-5.81)
 .. controls (-20.38,-6.97) and (-20.43,-6.89) .. (-20.15,-7.96)
 .. controls (-19.87,-9.05) and (-19.22,-10.14) .. (-18.34,-11.24)
 .. controls (-17.45,-12.36) and (-15.08,-13.24) .. (-15.08,-13.24)
));
draw_downscrap;
endfig;
beginfig(120);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-15.08,-13.24)
 .. controls (-15.08,-13.24) and (-13.27,-14.42) .. (-11.57,-14.42)
 .. controls (-9.85,-14.43) and (-8.31,-15.35) .. (-7.23,-14.99)
 .. controls (-6.15,-14.63) and (-4.07,-15.64) .. (-3.36,-14.01)
 .. controls (-2.65,-12.38) and (-5.37,-5.85) .. (-4.69,-3.56)
 .. controls (-4.00,-1.24) and (-3.24,-0.48) .. (-2.67,1.27)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((1.23,-2.29)
 -- (19.90,-2.47)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((0.42,15.64)
 -- (1.36,15.61)
 -- (1.36,-14.77)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((1.36,-14.77)
 -- (0.39,-14.76)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.04,8.38)
 .. controls (-11.92,8.02) and (-13.55,8.17) .. (-13.86,7.58)
 .. controls (-14.18,6.96) and (-15.36,6.05) .. (-15.63,5.40)
 .. controls (-15.90,4.76) and (-16.03,4.54) .. (-17.44,3.01)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-20.70,-5.81)
 .. controls (-20.38,-6.97) and (-20.43,-6.89) .. (-20.15,-7.96)
 .. controls (-19.87,-9.05) and (-19.22,-10.14) .. (-18.34,-11.24)
 .. controls (-17.45,-12.36) and (-15.08,-13.24) .. (-15.08,-13.24)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-20.70,-5.81)
 .. controls (-20.70,-5.81) and (-21.27,-0.14) .. (-19.69,1.55)
));
ATTR__height := -1;
drawoptions();
l_pit(((-11.92,6.98)
 .. controls (-11.92,6.98) and (-18.51,2.47) .. (-19.07,0.54)
 .. controls (-19.71,-1.66) and (-19.04,-5.25) .. (-17.93,-6.04)
 .. controls (-16.74,-6.88) and (-15.13,-6.64) .. (-14.19,-8.06)
 .. controls (-13.23,-9.51) and (-12.01,-11.74) .. (-9.67,-12.24)
 .. controls (-7.34,-12.74) and (-6.55,-12.79) .. (-5.88,-10.59)
 .. controls (-5.22,-8.40) and (-5.48,-8.31) .. (-5.61,-5.87)
 .. controls (-5.73,-3.42) and (-5.47,-2.80) .. (-4.88,-1.63)
 .. controls (-4.28,-0.46) and (-3.28,1.13) .. (-3.21,2.00)
 .. controls (-3.13,2.86) and (-3.10,6.79) .. (-3.52,7.88)
));
endfig;
beginfig(121);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char66 \char111 \char110 \char98 \char111 \char110 \char115 \char116 \char97 \char110 \char100 \char58 \ \char80 \char51 \char53 \mainfont{} etex,(21.27,-2.34),0.0,0);
endfig;
background:=(0.37000,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.37000, 1.00000, 0.25000);
current_scrap := "D35_20160808_SP11@D35_080816.D35projet";
ATTR__scrap := "D35_20160808_SP11";
beginfig(122);
ATTR__survey := "D35_080816.D35projet";
ATTR__height := -1;
drawoptions();
l_pit(((5.49,-16.00)
 .. controls (5.31,-15.73) and (5.17,-12.44) .. (4.45,-10.82)
 .. controls (3.74,-9.20) and (3.51,-7.99) .. (3.42,-6.50)
 .. controls (3.33,-5.02) and (2.57,-3.89) .. (1.17,-1.91)
 .. controls (-0.22,0.07) and (-4.81,-3.49) .. (-6.07,-4.34)
 .. controls (-7.33,-5.20) and (-6.61,-6.05) .. (-6.88,-6.91)
 .. controls (-7.15,-7.76) and (-6.21,-8.62) .. (-6.08,-11.14)
 .. controls (-5.94,-13.66) and (-4.55,-18.88) .. (-4.55,-19.51)
));
endfig;
beginfig(123);
draw_upscrap(1)(1,((10.26,-21.49)
 .. controls (10.26,-21.49) and (9.72,-20.36) .. (9.00,-18.79)
 .. controls (8.28,-17.21) and (4.73,-8.98) .. (4.55,-7.63)
 .. controls (4.37,-6.28) and (2.49,4.47) .. (-4.00,-2.09)
 .. controls (-5.53,-3.63) and (-7.33,-4.03) .. (-7.33,-4.03)
),
1,((-7.33,-4.03)
 .. controls (-7.33,-4.03) and (-8.50,-4.39) .. (-8.46,-3.44)
),
1,((-9.90,-4.61)
 .. controls (-9.04,-5.15) and (-8.59,-5.69) .. (-8.59,-5.69)
),
1,((-8.59,-5.69)
 .. controls (-8.59,-5.69) and (-6.95,-7.85) .. (-7.25,-11.00)
 .. controls (-7.51,-13.93) and (-6.53,-19.82) .. (-5.04,-22.39)
 .. controls (-3.56,-24.95) and (-3.74,-25.63) .. (-0.99,-24.82)
 .. controls (0.68,-24.33) and (0.58,-23.29) .. (2.29,-23.69)
));
draw_downscrap;
endfig;
beginfig(124);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-8.59,-5.69)
 .. controls (-8.59,-5.69) and (-6.95,-7.85) .. (-7.25,-11.00)
 .. controls (-7.51,-13.93) and (-6.53,-19.82) .. (-5.04,-22.39)
 .. controls (-3.56,-24.95) and (-3.74,-25.63) .. (-0.99,-24.82)
 .. controls (0.68,-24.33) and (0.58,-23.29) .. (2.29,-23.69)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.90,-4.61)
 .. controls (-9.04,-5.15) and (-8.59,-5.69) .. (-8.59,-5.69)
));
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((-10.26,-2.61),0.0,1.00,(-1,1));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((10.26,-21.49)
 .. controls (10.26,-21.49) and (9.72,-20.36) .. (9.00,-18.79)
 .. controls (8.28,-17.21) and (4.73,-8.98) .. (4.55,-7.63)
 .. controls (4.37,-6.28) and (2.49,4.47) .. (-4.00,-2.09)
 .. controls (-5.53,-3.63) and (-7.33,-4.03) .. (-7.33,-4.03)
));
drawoptions();
p_flowstone((-0.81,-2.50),353.0,0.50,(0,0));
drawoptions();
p_flowstone((-3.64,-3.76),26.5,0.50,(0,0));
drawoptions();
p_flowstone((-5.31,-6.91),90.4,0.50,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.33,-4.03)
 .. controls (-7.33,-4.03) and (-8.50,-4.39) .. (-8.46,-3.44)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-0.40,2.99)
 -- (-0.41,18.83)
));
endfig;
beginfig(125);
drawoptions();
p_label.top(btex \thlabel\thnormalsize \thfb\char80 \char82 \char58 \ \char49 \char50 \char109 \mainfont{} etex,(-0.00,25.63),0.0,0);
endfig;
background:=(0.33250,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.33250, 1.00000, 0.25000);
current_scrap := "D35_20160808_SP10@D35_080816.D35projet";
ATTR__scrap := "D35_20160808_SP10";
beginfig(126);
ATTR__height := -1;
drawoptions();
l_border_visible(((6.73,2.86)
 .. controls (-0.34,3.26) and (-2.32,-3.08) .. (-2.32,-3.08)
));
endfig;
beginfig(127);
draw_upscrap(1)(1,((-9.97,7.13)
 .. controls (-9.47,6.91) and (-6.46,6.68) .. (-5.78,5.74)
 .. controls (-5.11,4.79) and (-3.80,3.49) .. (-3.80,2.63)
 .. controls (-3.80,1.78) and (-3.08,-0.29) .. (-1.15,-0.38)
 .. controls (0.79,-0.47) and (2.05,-2.09) .. (2.45,-2.81)
 .. controls (2.86,-3.53) and (4.03,-4.97) .. (4.84,-6.73)
 .. controls (5.65,-8.48) and (5.92,-9.34) .. (5.92,-9.34)
),
1,((9.97,-7.00)
 .. controls (9.97,-7.00) and (9.92,-5.11) .. (8.75,-3.67)
 .. controls (7.58,-2.23) and (7.58,-1.64) .. (7.54,-1.06)
 .. controls (7.49,-0.47) and (5.78,2.27) .. (4.61,3.17)
 .. controls (3.44,4.07) and (2.63,5.24) .. (1.64,5.69)
 .. controls (0.65,6.14) and (-1.82,8.21) .. (-2.00,9.34)
));
draw_downscrap;
endfig;
beginfig(128);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((9.97,-7.00)
 .. controls (9.97,-7.00) and (9.92,-5.11) .. (8.75,-3.67)
 .. controls (7.58,-2.23) and (7.58,-1.64) .. (7.54,-1.06)
 .. controls (7.49,-0.47) and (5.78,2.27) .. (4.61,3.17)
 .. controls (3.44,4.07) and (2.63,5.24) .. (1.64,5.69)
 .. controls (0.65,6.14) and (-1.82,8.21) .. (-2.00,9.34)
));
drawoptions();
p_airdraught_summer((8.75,0.61),27.4,1.00,(0,0));
drawoptions();
p_gradient((0.74,1.42),221.3,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.97,7.13)
 .. controls (-9.47,6.91) and (-6.46,6.68) .. (-5.78,5.74)
 .. controls (-5.11,4.79) and (-3.80,3.49) .. (-3.80,2.63)
 .. controls (-3.80,1.78) and (-3.08,-0.29) .. (-1.15,-0.38)
 .. controls (0.79,-0.47) and (2.05,-2.09) .. (2.45,-2.81)
 .. controls (2.86,-3.53) and (4.03,-4.97) .. (4.84,-6.73)
 .. controls (5.65,-8.48) and (5.92,-9.34) .. (5.92,-9.34)
));
endfig;
beginfig(129);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char49 \char50 \char50 \char53 \mainfont{} etex,(-1.42,8.17),0.0,1);
endfig;
background:=(0.30250,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.30250, 1.00000, 0.25000);
current_scrap := "D35_20160808_SP9@D35_080816.D35projet";
ATTR__scrap := "D35_20160808_SP9";
beginfig(130);
ATTR__height := -1;
drawoptions();
l_floorstep(((-5.36,15.19)
 .. controls (-5.36,15.19) and (-6.93,15.82) .. (-8.82,14.83)
 .. controls (-10.71,13.84) and (-9.32,12.58) .. (-8.87,11.54)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((4.50,-1.82)
 .. controls (3.78,-1.37) and (2.25,-1.01) .. (0.99,-0.43)
 .. controls (-0.27,0.16) and (-1.17,-1.15) .. (-2.97,-1.91)
 .. controls (-4.77,-2.68) and (-3.78,-8.39) .. (-3.78,-8.39)
));
endfig;
beginfig(131);
draw_upscrap(1)(1,((-10.58,14.02)
 .. controls (-10.58,14.02) and (-8.87,10.78) .. (-8.46,9.97)
 .. controls (-8.06,9.16) and (-9.54,6.01) .. (-8.96,4.75)
 .. controls (-8.37,3.49) and (-7.07,1.82) .. (-6.12,-0.02)
 .. controls (-5.18,-1.87) and (-4.59,-4.16) .. (-4.64,-5.56)
 .. controls (-4.68,-6.95) and (-4.91,-7.18) .. (-4.01,-9.52)
 .. controls (-3.11,-11.86) and (-1.98,-9.70) .. (-1.89,-13.21)
 .. controls (-1.80,-16.72) and (-0.68,-17.39) .. (-0.68,-17.39)
),
1,((6.48,-5.42)
 .. controls (6.48,-5.42) and (6.07,-4.66) .. (6.07,-3.71)
 .. controls (6.07,-2.77) and (5.53,-1.60) .. (4.59,-1.15)
 .. controls (3.64,-0.70) and (2.56,-0.92) .. (2.34,-0.07)
 .. controls (2.11,0.79) and (1.53,0.92) .. (1.57,1.78)
 .. controls (1.62,2.63) and (1.39,3.35) .. (2.02,4.21)
 .. controls (2.65,5.06) and (3.87,5.74) .. (4.54,6.41)
 .. controls (5.22,7.09) and (4.18,7.09) .. (3.96,8.08)
 .. controls (3.73,9.07) and (2.52,10.42) .. (3.01,10.73)
 .. controls (3.51,11.05) and (4.05,11.68) .. (4.59,11.05)
 .. controls (5.13,10.42) and (5.49,9.61) .. (6.03,9.07)
 .. controls (6.57,8.53) and (9.00,6.23) .. (9.31,5.74)
 .. controls (9.63,5.24) and (10.53,3.53) .. (10.62,3.26)
),
1,((11.74,4.34)
 .. controls (11.74,4.34) and (10.30,6.05) .. (9.81,6.73)
 .. controls (9.31,7.40) and (8.46,8.75) .. (8.23,9.34)
 .. controls (8.01,9.92) and (7.60,11.54) .. (6.88,12.31)
 .. controls (6.16,13.07) and (8.37,14.92) .. (8.37,15.64)
 .. controls (8.37,16.36) and (5.58,17.39) .. (1.53,15.01)
 .. controls (-2.52,12.62) and (-1.40,15.14) .. (-2.52,15.55)
 .. controls (-3.65,15.95) and (-3.20,16.49) .. (-4.50,16.13)
 .. controls (-5.81,15.77) and (-6.75,15.46) .. (-6.53,16.36)
));
draw_downscrap;
endfig;
beginfig(132);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.48,-5.42)
 .. controls (6.48,-5.42) and (6.07,-4.66) .. (6.07,-3.71)
 .. controls (6.07,-2.77) and (5.53,-1.60) .. (4.59,-1.15)
 .. controls (3.64,-0.70) and (2.56,-0.92) .. (2.34,-0.07)
 .. controls (2.11,0.79) and (1.53,0.92) .. (1.57,1.78)
 .. controls (1.62,2.63) and (1.39,3.35) .. (2.02,4.21)
 .. controls (2.65,5.06) and (3.87,5.74) .. (4.54,6.41)
 .. controls (5.22,7.09) and (4.18,7.09) .. (3.96,8.08)
 .. controls (3.73,9.07) and (2.52,10.42) .. (3.01,10.73)
 .. controls (3.51,11.05) and (4.05,11.68) .. (4.59,11.05)
 .. controls (5.13,10.42) and (5.49,9.61) .. (6.03,9.07)
 .. controls (6.57,8.53) and (9.00,6.23) .. (9.31,5.74)
 .. controls (9.63,5.24) and (10.53,3.53) .. (10.62,3.26)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-10.58,14.02)
 .. controls (-10.58,14.02) and (-8.87,10.78) .. (-8.46,9.97)
 .. controls (-8.06,9.16) and (-9.54,6.01) .. (-8.96,4.75)
 .. controls (-8.37,3.49) and (-7.07,1.82) .. (-6.12,-0.02)
 .. controls (-5.18,-1.87) and (-4.59,-4.16) .. (-4.64,-5.56)
 .. controls (-4.68,-6.95) and (-4.91,-7.18) .. (-4.01,-9.52)
 .. controls (-3.11,-11.86) and (-1.98,-9.70) .. (-1.89,-13.21)
 .. controls (-1.80,-16.72) and (-0.68,-17.39) .. (-0.68,-17.39)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.74,4.34)
 .. controls (11.74,4.34) and (10.30,6.05) .. (9.81,6.73)
 .. controls (9.31,7.40) and (8.46,8.75) .. (8.23,9.34)
 .. controls (8.01,9.92) and (7.60,11.54) .. (6.88,12.31)
 .. controls (6.16,13.07) and (8.37,14.92) .. (8.37,15.64)
 .. controls (8.37,16.36) and (5.58,17.39) .. (1.53,15.01)
 .. controls (-2.52,12.62) and (-1.40,15.14) .. (-2.52,15.55)
 .. controls (-3.65,15.95) and (-3.20,16.49) .. (-4.50,16.13)
 .. controls (-5.81,15.77) and (-6.75,15.46) .. (-6.53,16.36)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-11.16,-7.18)
 -- (-5.54,-7.18)
));
endfig;
beginfig(133);
drawoptions();
p_label.top(btex \thaltitude \thfb\char49 \char50 \char49 \char57 \mainfont{} etex,(6.66,16.58),0.0,1);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char82 \char52 \mainfont{} etex,(-12.24,-7.13),0.0,0);
endfig;
background:=(0.27250,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.27250, 1.00000, 0.25000);
current_scrap := "D35_20160808_SP8@D35_080816.D35projet";
ATTR__scrap := "D35_20160808_SP8";
beginfig(134);
ATTR__height := -1;
drawoptions();
l_floormeander(((4.66,6.39)
 .. controls (4.66,6.39) and (4.48,4.19) .. (5.06,2.39)
 .. controls (5.65,0.59) and (6.68,0.27) .. (6.73,-0.72)
 .. controls (6.77,-1.71) and (7.81,-3.73) .. (8.08,-4.50)
 .. controls (8.35,-5.26) and (9.47,-9.45) .. (9.20,-10.44)
 .. controls (8.93,-11.43) and (9.05,-11.41) .. (9.05,-11.41)
));
ATTR__height := -1;
drawoptions();
l_floormeander(((2.81,-2.43)
 .. controls (2.81,-2.43) and (6.28,-4.86) .. (6.64,-6.48)
 .. controls (7.00,-8.10) and (7.85,-11.57) .. (7.67,-13.23)
 .. controls (7.49,-14.90) and (8.03,-15.08) .. (8.12,-15.71)
));
endfig;
beginfig(135);
draw_upscrap(1)(1,((10.73,-15.75)
 .. controls (10.73,-15.75) and (10.42,-14.40) .. (10.91,-13.46)
 .. controls (11.41,-12.51) and (13.16,-11.07) .. (13.16,-10.12)
 .. controls (13.16,-9.18) and (12.49,-6.30) .. (11.50,-5.44)
 .. controls (10.51,-4.59) and (9.92,-2.79) .. (9.65,-2.11)
 .. controls (9.38,-1.44) and (8.84,-0.54) .. (9.11,0.00)
 .. controls (9.38,0.54) and (9.29,1.53) .. (10.69,1.53)
 .. controls (12.08,1.53) and (13.12,1.49) .. (13.21,2.43)
 .. controls (13.30,3.38) and (14.29,4.32) .. (13.79,5.36)
 .. controls (13.30,6.39) and (9.25,10.03) .. (8.03,12.01)
 .. controls (6.82,13.99) and (4.97,13.68) .. (4.30,13.27)
 .. controls (3.62,12.87) and (2.81,12.55) .. (2.18,12.91)
 .. controls (1.55,13.27) and (-1.87,15.75) .. (-1.87,15.75)
),
1,((-2.99,14.67)
 .. controls (-2.99,14.67) and (-2.54,13.23) .. (-1.96,11.79)
 .. controls (-1.37,10.35) and (-1.51,9.41) .. (-0.20,8.82)
 .. controls (1.10,8.24) and (1.01,8.23) .. (1.33,7.25)
 .. controls (1.64,6.26) and (0.65,5.45) .. (0.16,5.40)
 .. controls (-0.34,5.36) and (-1.42,5.36) .. (-1.78,5.27)
 .. controls (-2.14,5.18) and (-4.39,4.45) .. (-4.66,4.45)
 .. controls (-4.93,4.45) and (-6.19,4.54) .. (-7.13,5.98)
),
1,((-14.29,-5.99)
 .. controls (-14.29,-5.99) and (-12.62,-7.02) .. (-11.18,-6.98)
 .. controls (-9.74,-6.93) and (-8.80,-6.98) .. (-8.26,-6.66)
 .. controls (-7.72,-6.35) and (-7.13,-5.36) .. (-6.46,-5.09)
 .. controls (-5.78,-4.82) and (-5.87,-4.68) .. (-4.79,-4.68)
 .. controls (-3.71,-4.68) and (-0.65,-5.36) .. (0.43,-6.53)
 .. controls (1.51,-7.70) and (2.63,-8.73) .. (2.99,-9.49)
 .. controls (3.35,-10.26) and (3.89,-11.70) .. (3.89,-12.37)
 .. controls (3.89,-13.05) and (3.64,-15.12) .. (3.64,-15.12)
));
draw_downscrap;
endfig;
beginfig(136);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((10.73,-15.75)
 .. controls (10.73,-15.75) and (10.42,-14.40) .. (10.91,-13.46)
 .. controls (11.41,-12.51) and (13.16,-11.07) .. (13.16,-10.12)
 .. controls (13.16,-9.18) and (12.49,-6.30) .. (11.50,-5.44)
 .. controls (10.51,-4.59) and (9.92,-2.79) .. (9.65,-2.11)
 .. controls (9.38,-1.44) and (8.84,-0.54) .. (9.11,0.00)
 .. controls (9.38,0.54) and (9.29,1.53) .. (10.69,1.53)
 .. controls (12.08,1.53) and (13.12,1.49) .. (13.21,2.43)
 .. controls (13.30,3.38) and (14.29,4.32) .. (13.79,5.36)
 .. controls (13.30,6.39) and (9.25,10.03) .. (8.03,12.01)
 .. controls (6.82,13.99) and (4.97,13.68) .. (4.30,13.27)
 .. controls (3.62,12.87) and (2.81,12.55) .. (2.18,12.91)
 .. controls (1.55,13.27) and (-1.87,15.75) .. (-1.87,15.75)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2.99,14.67)
 .. controls (-2.99,14.67) and (-2.54,13.23) .. (-1.96,11.79)
 .. controls (-1.37,10.35) and (-1.51,9.41) .. (-0.20,8.82)
 .. controls (1.10,8.24) and (1.01,8.23) .. (1.33,7.25)
 .. controls (1.64,6.26) and (0.65,5.45) .. (0.16,5.40)
 .. controls (-0.34,5.36) and (-1.42,5.36) .. (-1.78,5.27)
 .. controls (-2.14,5.18) and (-4.39,4.45) .. (-4.66,4.45)
 .. controls (-4.93,4.45) and (-6.19,4.54) .. (-7.13,5.98)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-14.29,-5.99)
 .. controls (-14.29,-5.99) and (-12.62,-7.02) .. (-11.18,-6.98)
 .. controls (-9.74,-6.93) and (-8.80,-6.98) .. (-8.26,-6.66)
 .. controls (-7.72,-6.35) and (-7.13,-5.36) .. (-6.46,-5.09)
 .. controls (-5.78,-4.82) and (-5.87,-4.68) .. (-4.79,-4.68)
 .. controls (-3.71,-4.68) and (-0.65,-5.36) .. (0.43,-6.53)
 .. controls (1.51,-7.70) and (2.63,-8.73) .. (2.99,-9.49)
 .. controls (3.35,-10.26) and (3.89,-11.70) .. (3.89,-12.37)
 .. controls (3.89,-13.05) and (3.64,-15.12) .. (3.64,-15.12)
));
endfig;
beginfig(137);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char49 \char50 \char49 \char54 \mainfont{} etex,(9.88,9.81),0.0,1);
drawoptions();
p_label.llft(btex \thaltitude \thfb\char49 \char50 \char49 \char53 \mainfont{} etex,(1.24,-7.38),0.0,1);
endfig;
background:=(0.25000,1.00000,0.28000);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.28000);
current_scrap := "D35_20160808_SP7@D35_080816.D35projet";
ATTR__scrap := "D35_20160808_SP7";
background:=(0.25000,1.00000,0.26500);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.26500);
current_scrap := "D35_20160808_SP6@D35_080816.D35projet";
ATTR__scrap := "D35_20160808_SP6";
beginfig(138);
drawoptions();
p_clay((1.93,0.12),304.2,0.71,(0,0));
drawoptions();
p_clay((4.49,-7.69),298.3,0.71,(0,0));
drawoptions();
p_clay((-2.18,6.80),288.0,0.71,(0,0));
endfig;
beginfig(139);
draw_upscrap(1)(1,((-5.12,16.83)
 .. controls (-5.12,16.83) and (-4.35,15.67) .. (-3.38,15.11)
 .. controls (-2.41,14.55) and (-2.41,14.19) .. (-2.05,13.49)
 .. controls (-1.69,12.79) and (-1.26,11.94) .. (-1.26,11.15)
 .. controls (-1.26,10.36) and (-0.68,7.60) .. (-0.35,7.17)
 .. controls (-0.01,6.74) and (1.16,5.36) .. (1.96,4.39)
 .. controls (2.77,3.41) and (3.88,1.94) .. (4.13,0.23)
 .. controls (4.39,-1.49) and (4.78,-3.59) .. (5.18,-4.92)
 .. controls (5.59,-6.25) and (6.07,-8.14) .. (5.78,-10.01)
 .. controls (5.49,-11.88) and (6.36,-13.31) .. (6.70,-13.79)
 .. controls (7.03,-14.26) and (7.32,-14.77) .. (7.49,-15.18)
 .. controls (7.65,-15.59) and (8.68,-16.55) .. (8.72,-16.83)
),
1,reverse ((-6.09,-0.96)
 .. controls (-5.04,-1.00) and (-2.98,-1.54) .. (-2.08,-1.93)
 .. controls (-1.18,-2.31) and (0.64,-2.97) .. (0.80,-3.08)
 .. controls (0.96,-3.20) and (1.91,-4.12) .. (2.22,-4.51)
 .. controls (2.52,-4.89) and (2.88,-6.09) .. (3.16,-6.92)
 .. controls (3.44,-7.75) and (3.64,-11.11) .. (3.78,-11.66)
 .. controls (3.92,-12.23) and (3.99,-12.68) .. (4.28,-12.88)
 .. controls (4.58,-13.09) and (5.43,-14.22) .. (5.80,-14.67)
 .. controls (6.16,-15.12) and (6.21,-16.25) .. (6.97,-16.62)
),
1,reverse ((-8.60,14.87)
 .. controls (-8.60,14.87) and (-6.71,13.53) .. (-5.03,13.20)
 .. controls (-3.34,12.86) and (-3.99,12.44) .. (-3.75,11.90)
 .. controls (-3.50,11.35) and (-3.46,8.88) .. (-3.34,8.26)
 .. controls (-3.23,7.65) and (-3.65,6.33) .. (-3.75,6.18)
 .. controls (-3.84,6.02) and (-6.34,3.69) .. (-7.26,3.58)
));
draw_downscrap;
endfig;
beginfig(140);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-8.60,14.87)
 .. controls (-8.60,14.87) and (-6.71,13.53) .. (-5.03,13.20)
 .. controls (-3.34,12.86) and (-3.99,12.44) .. (-3.75,11.90)
 .. controls (-3.50,11.35) and (-3.46,8.88) .. (-3.34,8.26)
 .. controls (-3.23,7.65) and (-3.65,6.33) .. (-3.75,6.18)
 .. controls (-3.84,6.02) and (-6.34,3.69) .. (-7.26,3.58)
));
ATTR__height := -1;
drawoptions();
l_pit(((-4.02,5.19)
 .. controls (-4.25,4.97) and (-6.04,4.24) .. (-6.60,2.78)
 .. controls (-7.15,1.35) and (-8.72,0.74) .. (-5.89,-0.30)
 .. controls (-2.99,-1.36) and (-1.56,-1.27) .. (-1.56,-1.27)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.12,16.83)
 .. controls (-5.12,16.83) and (-4.35,15.67) .. (-3.38,15.11)
 .. controls (-2.41,14.55) and (-2.41,14.19) .. (-2.05,13.49)
 .. controls (-1.69,12.79) and (-1.26,11.94) .. (-1.26,11.15)
 .. controls (-1.26,10.36) and (-0.68,7.60) .. (-0.35,7.17)
 .. controls (-0.01,6.74) and (1.16,5.36) .. (1.96,4.39)
 .. controls (2.77,3.41) and (3.88,1.94) .. (4.13,0.23)
 .. controls (4.39,-1.49) and (4.78,-3.59) .. (5.18,-4.92)
 .. controls (5.59,-6.25) and (6.07,-8.14) .. (5.78,-10.01)
 .. controls (5.49,-11.88) and (6.36,-13.31) .. (6.70,-13.79)
 .. controls (7.03,-14.26) and (7.32,-14.77) .. (7.49,-15.18)
 .. controls (7.65,-15.59) and (8.68,-16.55) .. (8.72,-16.83)
));
drawoptions();
p_airdraught_summer((1.77,-11.47),10.7,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-6.09,-0.96)
 .. controls (-5.04,-1.00) and (-2.98,-1.54) .. (-2.08,-1.93)
 .. controls (-1.18,-2.31) and (0.64,-2.97) .. (0.80,-3.08)
 .. controls (0.96,-3.20) and (1.91,-4.12) .. (2.22,-4.51)
 .. controls (2.52,-4.89) and (2.88,-6.09) .. (3.16,-6.92)
 .. controls (3.44,-7.75) and (3.64,-11.11) .. (3.78,-11.66)
 .. controls (3.92,-12.23) and (3.99,-12.68) .. (4.28,-12.88)
 .. controls (4.58,-13.09) and (5.43,-14.22) .. (5.80,-14.67)
 .. controls (6.16,-15.12) and (6.21,-16.25) .. (6.97,-16.62)
));
endfig;
beginfig(141);
drawoptions();
p_label.llft(btex \thaltitude \thfb\char49 \char50 \char48 \char56 \mainfont{} etex,(1.36,-3.63),0.0,1);
endfig;
background:=(0.25750,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.25750, 1.00000, 0.25000);
current_scrap := "D35_20160808_SP5@D35_080816.D35projet";
ATTR__scrap := "D35_20160808_SP5";
beginfig(142);
drawoptions();
p_clay((-8.15,2.16),296.2,0.71,(0,0));
drawoptions();
p_clay((-10.22,8.68),313.2,0.71,(0,0));
ATTR__height := -1;
drawoptions();
l_border_visible(((-18.54,11.29)
 .. controls (-18.54,11.29) and (-23.99,5.62) .. (-21.15,2.34)
 .. controls (-18.32,-0.95) and (-17.24,-3.47) .. (-17.24,-4.73)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-15.44,17.23)
 .. controls (-15.44,17.23) and (-15.75,14.44) .. (-15.53,11.56)
 .. controls (-15.30,8.68) and (-15.71,3.60) .. (-13.10,1.21)
 .. controls (-10.49,-1.17) and (-8.51,-2.79) .. (-8.33,-4.14)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((-3.15,2.11)
 .. controls (-3.15,2.11) and (-3.33,2.11) .. (-2.84,0.76)
 .. controls (-2.34,-0.59) and (-1.49,-0.77) .. (-1.49,-0.77)
 .. controls (-1.49,-0.77) and (-0.63,-0.59) .. (-0.68,-0.36)
 .. controls (-0.72,-0.14) and (-0.95,0.72) .. (-1.44,1.30)
 .. controls (-1.94,1.89) and (-3.15,2.11) .. cycle
));
endfig;
beginfig(143);
draw_upscrap(1)(1,((-7.83,14.98)
 .. controls (-7.83,14.98) and (-7.61,14.33) .. (-7.25,13.05)
 .. controls (-6.89,11.76) and (-6.30,11.47) .. (-5.76,10.30)
 .. controls (-5.22,9.13) and (-3.80,7.94) .. (-3.69,7.74)
 .. controls (-3.58,7.53) and (-1.37,4.81) .. (0.07,3.64)
 .. controls (1.51,2.47) and (2.54,2.16) .. (2.97,1.46)
 .. controls (3.40,0.76) and (4.12,-0.14) .. (4.05,-0.77)
 .. controls (3.98,-1.40) and (2.43,-2.55) .. (1.93,-3.63)
 .. controls (1.44,-4.71) and (0.52,-7.16) .. (0.54,-8.89)
 .. controls (0.56,-10.62) and (0.43,-11.37) .. (0.74,-12.53)
 .. controls (1.06,-13.70) and (1.73,-14.99) .. (1.98,-15.28)
),
1,reverse ((-26.08,-4.26)
 .. controls (-24.21,-5.01) and (-24.46,-5.31) .. (-22.48,-5.70)
 .. controls (-20.50,-6.08) and (-19.44,-5.40) .. (-18.34,-4.64)
 .. controls (-17.24,-3.87) and (-17.57,-3.29) .. (-15.86,-3.11)
 .. controls (-14.15,-2.93) and (-13.16,-3.00) .. (-12.29,-3.00)
 .. controls (-11.41,-3.00) and (-7.29,-2.97) .. (-6.21,-2.91)
 .. controls (-5.13,-2.84) and (-4.77,-2.79) .. (-4.43,-3.92)
 .. controls (-4.10,-5.04) and (-3.78,-8.01) .. (-3.76,-8.42)
 .. controls (-3.74,-8.82) and (-3.28,-15.46) .. (-1.50,-17.23)
),
1,reverse ((-14.92,15.61)
 .. controls (-14.94,14.87) and (-16.31,13.81) .. (-16.76,12.10)
 .. controls (-17.21,10.39) and (-18.34,9.49) .. (-18.88,9.13)
 .. controls (-19.42,8.77) and (-21.92,9.54) .. (-23.65,9.31)
 .. controls (-25.38,9.09) and (-27.07,9.40) .. (-27.07,9.40)
));
draw_downscrap;
endfig;
beginfig(144);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-14.92,15.61)
 .. controls (-14.94,14.87) and (-16.31,13.81) .. (-16.76,12.10)
 .. controls (-17.21,10.39) and (-18.34,9.49) .. (-18.88,9.13)
 .. controls (-19.42,8.77) and (-21.92,9.54) .. (-23.65,9.31)
 .. controls (-25.38,9.09) and (-27.07,9.40) .. (-27.07,9.40)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.83,14.98)
 .. controls (-7.83,14.98) and (-7.61,14.33) .. (-7.25,13.05)
 .. controls (-6.89,11.76) and (-6.30,11.47) .. (-5.76,10.30)
 .. controls (-5.22,9.13) and (-3.80,7.94) .. (-3.69,7.74)
 .. controls (-3.58,7.53) and (-1.37,4.81) .. (0.07,3.64)
 .. controls (1.51,2.47) and (2.54,2.16) .. (2.97,1.46)
 .. controls (3.40,0.76) and (4.12,-0.14) .. (4.05,-0.77)
 .. controls (3.98,-1.40) and (2.43,-2.55) .. (1.93,-3.63)
 .. controls (1.44,-4.71) and (0.52,-7.16) .. (0.54,-8.89)
 .. controls (0.56,-10.62) and (0.43,-11.37) .. (0.74,-12.53)
 .. controls (1.06,-13.70) and (1.73,-14.99) .. (1.98,-15.28)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((20.52,1.08)
 -- (27.50,1.08)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((4.14,1.08)
 -- (10.71,1.08)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-21.78,-6.53)
 -- (-21.78,-14.67)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-29.66,-5.45)
 -- (-29.66,-6.48)
 -- (-7.20,-6.44)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-7.20,-6.44)
 -- (-7.20,-5.40)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-26.08,-4.26)
 .. controls (-24.21,-5.01) and (-24.46,-5.31) .. (-22.48,-5.70)
 .. controls (-20.50,-6.08) and (-19.44,-5.40) .. (-18.34,-4.64)
 .. controls (-17.24,-3.87) and (-17.57,-3.29) .. (-15.86,-3.11)
 .. controls (-14.15,-2.93) and (-13.16,-3.00) .. (-12.29,-3.00)
 .. controls (-11.41,-3.00) and (-7.29,-2.97) .. (-6.21,-2.91)
 .. controls (-5.13,-2.84) and (-4.77,-2.79) .. (-4.43,-3.92)
 .. controls (-4.10,-5.04) and (-3.78,-8.01) .. (-3.76,-8.42)
 .. controls (-3.74,-8.82) and (-3.28,-15.46) .. (-1.50,-17.23)
));
drawoptions();
p_gradient((-15.62,4.05),277.1,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((20.70,-11.25)
 -- (27.81,-11.25)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((6.08,-11.25)
 -- (10.44,-11.25)
));
drawoptions();
p_airdraught_summer((3.06,-11.21),4.8,1.00,(0,0));
endfig;
beginfig(145);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char76 \char101 \ \char116 \char111 \char116 \char101 \char109 \mainfont{} etex,(29.66,0.94),0.0,0);
drawoptions();
p_label.bot(btex \thlabel\thnormalsize \thfb\char82 \char49 \char48 \mainfont{} etex,(-21.74,-16.43),0.0,0);
drawoptions();
p_label.rt(btex \thaltitude \thfb\char49 \char50 \char49 \char50 \mainfont{} etex,(3.64,-1.44),0.0,1);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char55 \char48 \char48 \ \char108 \char112 \char115 \ \char48 \char56 \char47 \char48 \char56 \char47 \char50 \char48 \char49 \char54 \ \char49 \char56 \char58 \char49 \char53 \mainfont{} etex,(29.57,-11.30),0.0,0);
endfig;
background:=(0.28000,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.28000, 1.00000, 0.25000);
current_scrap := "D35_20160808_SP4@D35_080816.D35projet";
ATTR__scrap := "D35_20160808_SP4";
beginfig(146);
ATTR__height := -1;
drawoptions();
l_border_visible(((82.50,29.62)
 .. controls (82.50,29.62) and (77.05,27.28) .. (78.72,22.51)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((88.12,29.80)
 .. controls (88.12,29.80) and (83.13,24.94) .. (86.86,19.55)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((93.43,31.48)
 .. controls (93.43,31.48) and (88.30,22.07) .. (94.19,18.79)
));
endfig;
beginfig(147);
draw_upscrap(1)(1,((64.50,38.44)
 .. controls (65.29,38.15) and (65.58,37.72) .. (65.83,37.43)
 .. controls (66.07,37.13) and (66.86,36.32) .. (67.36,35.65)
 .. controls (67.85,34.97) and (68.21,33.74) .. (68.21,33.44)
 .. controls (68.21,33.15) and (68.91,31.91) .. (69.70,31.53)
 .. controls (70.48,31.15) and (70.73,30.74) .. (71.14,30.45)
 .. controls (71.54,30.16) and (72.76,29.78) .. (73.12,29.57)
 .. controls (73.48,29.37) and (75.86,28.25) .. (76.38,28.02)
 .. controls (76.89,27.80) and (77.12,26.47) .. (77.12,26.07)
 .. controls (77.12,25.66) and (78.29,25.01) .. (78.72,24.38)
 .. controls (79.14,23.75) and (80.97,23.68) .. (81.55,23.68)
 .. controls (82.14,23.68) and (83.62,23.05) .. (83.98,22.83)
 .. controls (84.34,22.60) and (86.00,22.11) .. (86.68,22.06)
 .. controls (87.35,22.02) and (88.34,22.18) .. (89.42,22.38)
 .. controls (90.50,22.59) and (92.21,23.67) .. (92.71,23.56)
 .. controls (93.20,23.44) and (95.04,23.17) .. (96.73,24.25)
 .. controls (98.42,25.33) and (101.23,25.58) .. (101.80,25.58)
),
1,((101.80,25.58)
 .. controls (101.80,25.58) and (103.91,25.93) .. (104.63,26.07)
 .. controls (105.35,26.21) and (107.13,26.40) .. (107.13,26.40)
),
1,((105.96,30.93)
 .. controls (105.06,30.59) and (103.83,29.45) .. (103.83,29.45)
),
1,((103.83,29.45)
 .. controls (103.07,29.30) and (102.67,29.87) .. (101.64,30.60)
 .. controls (100.60,31.34) and (99.44,30.73) .. (98.49,30.73)
 .. controls (97.55,30.73) and (95.68,30.28) .. (94.93,29.83)
 .. controls (94.19,29.38) and (92.50,28.82) .. (91.49,28.44)
 .. controls (90.48,28.05) and (86.57,28.27) .. (86.14,28.18)
 .. controls (85.71,28.09) and (84.52,27.95) .. (83.67,27.95)
 .. controls (82.81,27.95) and (80.74,28.45) .. (79.62,28.99)
 .. controls (78.49,29.53) and (75.70,30.27) .. (75.34,30.47)
 .. controls (74.98,30.68) and (74.33,30.83) .. (73.59,31.46)
 .. controls (72.85,32.09) and (71.77,33.20) .. (71.72,34.43)
 .. controls (71.68,35.67) and (71.68,35.92) .. (72.87,37.52)
 .. controls (74.06,39.11) and (73.79,40.17) .. (72.37,41.23)
),
1,((72.37,41.23)
 .. controls (72.37,41.23) and (71.20,41.77) .. (71.16,42.44)
 .. controls (71.11,43.12) and (70.44,43.57) .. (69.99,43.91)
));
draw_downscrap;
endfig;
beginfig(148);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((103.83,29.45)
 .. controls (103.07,29.30) and (102.67,29.87) .. (101.64,30.60)
 .. controls (100.60,31.34) and (99.44,30.73) .. (98.49,30.73)
 .. controls (97.55,30.73) and (95.68,30.28) .. (94.93,29.83)
 .. controls (94.19,29.38) and (92.50,28.82) .. (91.49,28.44)
 .. controls (90.48,28.05) and (86.57,28.27) .. (86.14,28.18)
 .. controls (85.71,28.09) and (84.52,27.95) .. (83.67,27.95)
 .. controls (82.81,27.95) and (80.74,28.45) .. (79.62,28.99)
 .. controls (78.49,29.53) and (75.70,30.27) .. (75.34,30.47)
 .. controls (74.98,30.68) and (74.33,30.83) .. (73.59,31.46)
 .. controls (72.85,32.09) and (71.77,33.20) .. (71.72,34.43)
 .. controls (71.68,35.67) and (71.68,35.92) .. (72.87,37.52)
 .. controls (74.06,39.11) and (73.79,40.17) .. (72.37,41.23)
));
drawoptions();
p_gradient((85.02,24.72),264.2,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((64.50,38.44)
 .. controls (65.29,38.15) and (65.58,37.72) .. (65.83,37.43)
 .. controls (66.07,37.13) and (66.86,36.32) .. (67.36,35.65)
 .. controls (67.85,34.97) and (68.21,33.74) .. (68.21,33.44)
 .. controls (68.21,33.15) and (68.91,31.91) .. (69.70,31.53)
 .. controls (70.48,31.15) and (70.73,30.74) .. (71.14,30.45)
 .. controls (71.54,30.16) and (72.76,29.78) .. (73.12,29.57)
 .. controls (73.48,29.37) and (75.86,28.25) .. (76.38,28.02)
 .. controls (76.89,27.80) and (77.12,26.47) .. (77.12,26.07)
 .. controls (77.12,25.66) and (78.29,25.01) .. (78.72,24.38)
 .. controls (79.14,23.75) and (80.97,23.68) .. (81.55,23.68)
 .. controls (82.14,23.68) and (83.62,23.05) .. (83.98,22.83)
 .. controls (84.34,22.60) and (86.00,22.11) .. (86.68,22.06)
 .. controls (87.35,22.02) and (88.34,22.18) .. (89.42,22.38)
 .. controls (90.50,22.59) and (92.21,23.67) .. (92.71,23.56)
 .. controls (93.20,23.44) and (95.04,23.17) .. (96.73,24.25)
 .. controls (98.42,25.33) and (101.23,25.58) .. (101.80,25.58)
));
drawoptions();
p_airdraught_summer((99.09,22.61),103.1,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((101.43,20.91)
 -- (101.34,-26.75)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((101.34,-26.75)
 -- (87.57,-40.84)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((104.58,25.31)
 -- (104.54,-33.72)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((104.54,-33.72)
 -- (87.75,-50.96)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((83.26,20.58)
 -- (83.30,-29.14)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((72.73,28.76)
 -- (72.73,-22.07)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((68.50,31.69)
 -- (68.50,-9.25)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((101.80,25.58)
 .. controls (101.80,25.58) and (103.91,25.93) .. (104.63,26.07)
 .. controls (105.35,26.21) and (107.13,26.40) .. (107.13,26.40)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((72.37,41.23)
 .. controls (72.37,41.23) and (71.20,41.77) .. (71.16,42.44)
 .. controls (71.11,43.12) and (70.44,43.57) .. (69.99,43.91)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((105.96,30.93)
 .. controls (105.06,30.59) and (103.83,29.45) .. (103.83,29.45)
));
endfig;
beginfig(149);
drawoptions();
p_label.top(btex \thaltitude \thfb\char49 \char50 \char49 \char55 \mainfont{} etex,(88.52,28.23),0.0,1);
drawoptions();
p_label.llft(btex \thaltitude \thfb\char49 \char50 \char50 \char48 \mainfont{} etex,(67.69,35.06),0.0,1);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char52 \char53 \char48 \ \char108 \char112 \char115 \ \char48 \char56 \char47 \char48 \char56 \char47 \char50 \char48 \char49 \char54 \ \char49 \char56 \char58 \char51 \char48 \mainfont{} etex,(87.44,-42.46),0.0,0);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char80 \char52 \mainfont{} etex,(87.84,-52.76),0.0,0);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char76 \char101 \char115 \ \char112 \char97 \char115 \ \char100 \char101 \ \char103 \thfc\char233 \thfb\char97 \char110 \char116 \char115 \mainfont{} etex,(83.21,-31.79),0.0,0);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char76 \char101 \ \char99 \char111 \char98 \char114 \char97 \mainfont{} etex,(72.77,-24.59),0.0,0);
ATTR__height := -1;
drawoptions();
l_label(btex \thhugesize \thfb\char82 {}\thfc\char233 {}\thfb\char115 {}\char101 {}\char97 {}\char117 {}\ \char100 {}\char101 {}\ \char108 {}\char97 {}\ \char106 {}\char111 {}\char110 {}\char99 {}\char116 {}\char105 {}\char111 {}\char110 {}\mainfont{} etex,((-107.13,52.76)
 .. controls (-107.13,52.76) and (-46.38,36.66) .. (-38.73,31.34)
 .. controls (-16.77,16.04) and (16.52,-16.00) .. (22.10,-25.00)
));
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char76 \char101 \ \char103 \char108 \char97 \char110 \char100 \mainfont{} etex,(68.45,-11.19),0.0,0);
endfig;
background:=(0.36250,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.36250, 1.00000, 0.25000);
current_scrap := "D35_20160808_SP3@D35_080816.D35projet";
ATTR__scrap := "D35_20160808_SP3";
beginfig(150);
ATTR__height := -1;
drawoptions();
l_floorstep(((6.47,-14.18)
 .. controls (6.47,-14.18) and (-6.45,-13.10) .. (-7.93,-17.33)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((9.44,16.79)
 .. controls (9.44,16.79) and (9.62,11.34) .. (5.21,10.08)
 .. controls (0.80,8.82) and (-0.15,8.10) .. (-3.52,7.60)
 .. controls (-6.90,7.11) and (-8.16,7.06) .. (-8.16,7.06)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((-8.16,7.06)
 .. controls (-8.16,7.06) and (-10.81,7.38) .. (-10.86,4.95)
 .. controls (-10.90,2.52) and (-10.77,1.80) .. (-8.96,1.17)
 .. controls (-7.16,0.54) and (-5.72,0.45) .. (-4.74,-0.99)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((-4.74,-0.99)
 .. controls (-4.42,-1.40) and (-3.25,-3.55) .. (-1.86,-3.65)
 .. controls (-0.46,-3.74) and (0.57,-3.29) .. (3.50,-4.05)
 .. controls (6.42,-4.82) and (8.00,-4.01) .. (8.00,-4.01)
));
ATTR__height := -1;
drawoptions();
l_border_visible(((13.76,14.94)
 .. controls (13.76,14.94) and (4.62,6.08) .. (10.52,-4.64)
));
endfig;
beginfig(151);
draw_upscrap(1)(1,((12.30,9.95)
 .. controls (10.81,10.55) and (10.38,12.15) .. (9.51,13.34)
 .. controls (8.63,14.54) and (5.19,17.12) .. (4.56,17.53)
 .. controls (3.93,17.93) and (0.60,19.71) .. (0.03,20.09)
 .. controls (-0.53,20.48) and (-1.97,20.00) .. (-3.48,20.18)
 .. controls (-4.98,20.36) and (-7.80,19.73) .. (-8.72,19.33)
 .. controls (-9.64,18.92) and (-10.29,15.53) .. (-10.54,15.14)
 .. controls (-10.79,14.76) and (-11.22,11.50) .. (-11.78,10.73)
 .. controls (-12.34,9.97) and (-11.60,9.27) .. (-12.68,8.75)
 .. controls (-13.76,8.23) and (-13.06,5.51) .. (-13.33,4.97)
 .. controls (-13.60,4.43) and (-13.24,2.95) .. (-12.93,2.38)
 .. controls (-12.61,1.82) and (-12.21,1.08) .. (-12.14,0.72)
 .. controls (-12.07,0.36) and (-12.00,0.11) .. (-12.09,-0.11)
),
1,((-9.33,-7.88)
 .. controls (-9.33,-7.88) and (-8.74,-7.79) .. (-8.00,-7.36)
 .. controls (-7.26,-6.93) and (-6.29,-5.36) .. (-6.15,-4.82)
 .. controls (-6.02,-4.28) and (-6.51,-3.96) .. (-6.49,-3.62)
 .. controls (-6.47,-3.29) and (-6.87,-2.57) .. (-6.27,-2.45)
 .. controls (-5.66,-2.34) and (-5.14,-2.39) .. (-5.03,-2.68)
 .. controls (-4.92,-2.97) and (-4.26,-4.57) .. (-4.22,-4.75)
 .. controls (-4.17,-4.93) and (-3.23,-7.31) .. (-3.32,-7.63)
 .. controls (-3.41,-7.94) and (-3.95,-8.69) .. (-4.26,-8.82)
 .. controls (-4.58,-8.96) and (-5.52,-11.23) .. (-5.73,-12.04)
 .. controls (-5.93,-12.85) and (-6.63,-14.56) .. (-6.67,-14.83)
 .. controls (-6.72,-15.10) and (-6.69,-16.72) .. (-6.27,-17.39)
),
1,((-6.27,-17.39)
 .. controls (-6.27,-17.39) and (-6.09,-18.05) .. (-5.23,-18.36)
 .. controls (-4.38,-18.68) and (-2.94,-20.12) .. (-2.26,-20.48)
),
1,((3.23,-15.01)
 .. controls (3.18,-14.69) and (1.70,-13.48) .. (1.70,-12.74)
 .. controls (1.70,-11.99) and (0.12,-10.42) .. (0.75,-10.01)
 .. controls (1.38,-9.61) and (2.22,-9.34) .. (2.51,-9.11)
 .. controls (2.80,-8.89) and (3.90,-8.19) .. (4.11,-7.88)
 .. controls (4.31,-7.56) and (5.14,-5.58) .. (5.77,-4.57)
 .. controls (6.40,-3.56) and (6.54,-2.59) .. (9.62,-3.13)
 .. controls (11.34,-3.43) and (11.19,-3.01) .. (13.29,-3.71)
));
draw_downscrap;
endfig;
beginfig(152);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.33,-7.88)
 .. controls (-9.33,-7.88) and (-8.74,-7.79) .. (-8.00,-7.36)
 .. controls (-7.26,-6.93) and (-6.29,-5.36) .. (-6.15,-4.82)
 .. controls (-6.02,-4.28) and (-6.51,-3.96) .. (-6.49,-3.62)
 .. controls (-6.47,-3.29) and (-6.87,-2.57) .. (-6.27,-2.45)
 .. controls (-5.66,-2.34) and (-5.14,-2.39) .. (-5.03,-2.68)
 .. controls (-4.92,-2.97) and (-4.26,-4.57) .. (-4.22,-4.75)
 .. controls (-4.17,-4.93) and (-3.23,-7.31) .. (-3.32,-7.63)
 .. controls (-3.41,-7.94) and (-3.95,-8.69) .. (-4.26,-8.82)
 .. controls (-4.58,-8.96) and (-5.52,-11.23) .. (-5.73,-12.04)
 .. controls (-5.93,-12.85) and (-6.63,-14.56) .. (-6.67,-14.83)
 .. controls (-6.72,-15.10) and (-6.69,-16.72) .. (-6.27,-17.39)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-6.27,-17.39)
 .. controls (-6.27,-17.39) and (-6.09,-18.05) .. (-5.23,-18.36)
 .. controls (-4.38,-18.68) and (-2.94,-20.12) .. (-2.26,-20.48)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((12.30,9.95)
 .. controls (10.81,10.55) and (10.38,12.15) .. (9.51,13.34)
 .. controls (8.63,14.54) and (5.19,17.12) .. (4.56,17.53)
 .. controls (3.93,17.93) and (0.60,19.71) .. (0.03,20.09)
 .. controls (-0.53,20.48) and (-1.97,20.00) .. (-3.48,20.18)
 .. controls (-4.98,20.36) and (-7.80,19.73) .. (-8.72,19.33)
 .. controls (-9.64,18.92) and (-10.29,15.53) .. (-10.54,15.14)
 .. controls (-10.79,14.76) and (-11.22,11.50) .. (-11.78,10.73)
 .. controls (-12.34,9.97) and (-11.60,9.27) .. (-12.68,8.75)
 .. controls (-13.76,8.23) and (-13.06,5.51) .. (-13.33,4.97)
 .. controls (-13.60,4.43) and (-13.24,2.95) .. (-12.93,2.38)
 .. controls (-12.61,1.82) and (-12.21,1.08) .. (-12.14,0.72)
 .. controls (-12.07,0.36) and (-12.00,0.11) .. (-12.09,-0.11)
));
drawoptions();
p_gradient((7.32,4.95),260.9,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.23,-15.01)
 .. controls (3.18,-14.69) and (1.70,-13.48) .. (1.70,-12.74)
 .. controls (1.70,-11.99) and (0.12,-10.42) .. (0.75,-10.01)
 .. controls (1.38,-9.61) and (2.22,-9.34) .. (2.51,-9.11)
 .. controls (2.80,-8.89) and (3.90,-8.19) .. (4.11,-7.88)
 .. controls (4.31,-7.56) and (5.14,-5.58) .. (5.77,-4.57)
 .. controls (6.40,-3.56) and (6.54,-2.59) .. (9.62,-3.13)
 .. controls (11.34,-3.43) and (11.19,-3.01) .. (13.29,-3.71)
));
endfig;
beginfig(153);
drawoptions();
p_label.top(btex \thaltitude \thfb\char49 \char50 \char50 \char50 \mainfont{} etex,(-2.40,20.16),0.0,1);
endfig;
background:=(0.53500,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.53500, 1.00000, 0.25000);
current_scrap := "D35_20160808_SP2@D35_080816.D35projet";
ATTR__scrap := "D35_20160808_SP2";
beginfig(154);
ATTR__height := -1;
drawoptions();
l_pit(((2.32,22.39)
 .. controls (2.32,22.39) and (4.12,20.86) .. (3.40,20.05)
 .. controls (2.68,19.24) and (1.19,16.63) .. (1.19,15.50)
 .. controls (1.19,14.38) and (1.19,10.96) .. (3.80,13.16)
 .. controls (5.53,14.62) and (5.29,13.16) .. (6.23,11.90)
));
endfig;
beginfig(155);
draw_upscrap(1)(1,((-4.36,4.70)
 .. controls (-4.36,4.70) and (-4.30,5.92) .. (-3.76,6.73)
 .. controls (-3.22,7.54) and (-2.68,8.35) .. (-1.42,8.17)
 .. controls (-0.16,7.99) and (2.45,8.08) .. (2.90,8.44)
 .. controls (3.35,8.80) and (4.21,9.00) .. (4.97,9.52)
 .. controls (5.74,10.04) and (5.90,10.35) .. (6.05,10.71)
 .. controls (6.21,11.07) and (5.83,12.49) .. (5.85,12.65)
 .. controls (5.87,12.80) and (5.89,14.02) .. (6.28,14.20)
),
1,((3.51,21.96)
 .. controls (3.51,21.96) and (3.37,21.69) .. (2.97,21.53)
 .. controls (2.56,21.37) and (1.57,21.10) .. (1.24,20.50)
 .. controls (0.90,19.89) and (0.54,19.21) .. (0.16,18.36)
 .. controls (-0.23,17.50) and (-1.51,17.21) .. (-1.51,17.21)
),
1,((-1.51,17.21)
 .. controls (-1.60,17.05) and (-1.98,16.76) .. (-2.54,16.67)
 .. controls (-3.11,16.58) and (-3.35,18.07) .. (-4.03,18.02)
 .. controls (-4.70,17.98) and (-4.32,15.10) .. (-4.32,14.78)
 .. controls (-4.32,14.47) and (-3.94,13.86) .. (-4.36,14.06)
 .. controls (-4.79,14.26) and (-5.22,16.69) .. (-5.26,16.85)
 .. controls (-5.31,17.01) and (-5.56,18.79) .. (-5.56,18.79)
),
1,((-6.28,15.77)
 .. controls (-6.28,15.77) and (-6.01,10.78) .. (-5.56,9.52)
 .. controls (-5.11,8.26) and (-4.70,5.65) .. (-4.70,4.66)
));
draw_downscrap;
endfig;
beginfig(156);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.36,4.70)
 .. controls (-4.36,4.70) and (-4.30,5.92) .. (-3.76,6.73)
 .. controls (-3.22,7.54) and (-2.68,8.35) .. (-1.42,8.17)
 .. controls (-0.16,7.99) and (2.45,8.08) .. (2.90,8.44)
 .. controls (3.35,8.80) and (4.21,9.00) .. (4.97,9.52)
 .. controls (5.74,10.04) and (5.90,10.35) .. (6.05,10.71)
 .. controls (6.21,11.07) and (5.83,12.49) .. (5.85,12.65)
 .. controls (5.87,12.80) and (5.89,14.02) .. (6.28,14.20)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-4.52,3.85)
 -- (-4.52,-11.52)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-6.28,15.77)
 .. controls (-6.28,15.77) and (-6.01,10.78) .. (-5.56,9.52)
 .. controls (-5.11,8.26) and (-4.70,5.65) .. (-4.70,4.66)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((4.93,7.22)
 -- (4.93,-20.63)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1.51,17.21)
 .. controls (-1.60,17.05) and (-1.98,16.76) .. (-2.54,16.67)
 .. controls (-3.11,16.58) and (-3.35,18.07) .. (-4.03,18.02)
 .. controls (-4.70,17.98) and (-4.32,15.10) .. (-4.32,14.78)
 .. controls (-4.32,14.47) and (-3.94,13.86) .. (-4.36,14.06)
 .. controls (-4.79,14.26) and (-5.22,16.69) .. (-5.26,16.85)
 .. controls (-5.31,17.01) and (-5.56,18.79) .. (-5.56,18.79)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.51,21.96)
 .. controls (3.51,21.96) and (3.37,21.69) .. (2.97,21.53)
 .. controls (2.56,21.37) and (1.57,21.10) .. (1.24,20.50)
 .. controls (0.90,19.89) and (0.54,19.21) .. (0.16,18.36)
 .. controls (-0.23,17.50) and (-1.51,17.21) .. (-1.51,17.21)
));
endfig;
beginfig(157);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char105 \char109 \char112 \mainfont{} etex,(-4.54,-12.74),0.0,0);
drawoptions();
p_label.bot(btex \thaltitude \thfb\char49 \char50 \char53 \char56 \mainfont{} etex,(0.88,8.03),0.0,1);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char76 \char117 \char120 \thfc\char233 \thfb\char58 \ \char80 \ \char51 \char55 \mainfont{} etex,(4.89,-22.39),0.0,0);
endfig;
background:=(0.58750,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.58750, 1.00000, 0.25000);
current_scrap := "D35_20160808_SP1@D35_080816.D35projet";
ATTR__scrap := "D35_20160808_SP1";
beginfig(158);
draw_upscrap(1)(1,((14.41,11.57)
 .. controls (14.41,11.57) and (15.14,7.35) .. (14.78,5.56)
 .. controls (14.45,3.87) and (14.85,-2.26) .. (15.48,-4.25)
 .. controls (16.10,-6.21) and (16.91,-8.18) .. (17.27,-9.17)
 .. controls (17.62,-10.16) and (18.12,-12.45) .. (18.12,-12.45)
),
1,((18.84,-9.43)
 -- (18.84,-7.91)
 .. controls (18.84,-7.91) and (19.39,-5.00) .. (19.21,-4.65)
 .. controls (19.04,-4.29) and (18.45,-4.51) .. (18.27,-4.15)
 .. controls (18.09,-3.80) and (17.65,-3.62) .. (17.65,-2.91)
 .. controls (17.65,-2.19) and (17.24,0.02) .. (16.88,0.92)
 .. controls (16.54,1.79) and (16.27,2.77) .. (16.47,3.63)
 .. controls (16.68,4.49) and (17.91,7.50) .. (17.91,8.84)
 .. controls (17.91,10.23) and (18.49,12.45) .. (18.49,12.45)
));
draw_downscrap;
endfig;
beginfig(159);
ATTR__height := -1;
drawoptions();
l_rockedge(((10.78,-11.29)
 -- (-15.84,-11.48)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((14.41,11.57)
 .. controls (14.41,11.57) and (15.14,7.35) .. (14.78,5.56)
 .. controls (14.45,3.87) and (14.85,-2.26) .. (15.48,-4.25)
 .. controls (16.10,-6.21) and (16.91,-8.18) .. (17.27,-9.17)
 .. controls (17.62,-10.16) and (18.12,-12.45) .. (18.12,-12.45)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((18.84,-9.43)
 -- (18.84,-7.91)
 .. controls (18.84,-7.91) and (19.39,-5.00) .. (19.21,-4.65)
 .. controls (19.04,-4.29) and (18.45,-4.51) .. (18.27,-4.15)
 .. controls (18.09,-3.80) and (17.65,-3.62) .. (17.65,-2.91)
 .. controls (17.65,-2.19) and (17.24,0.02) .. (16.88,0.92)
 .. controls (16.54,1.79) and (16.27,2.77) .. (16.47,3.63)
 .. controls (16.68,4.49) and (17.91,7.50) .. (17.91,8.84)
 .. controls (17.91,10.23) and (18.49,12.45) .. (18.49,12.45)
));
endfig;
beginfig(160);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char49 \ \char116 \char105 \char114 \ \char101 \char116 \ \char99 \char39 \char101 \char115 \char116 \ \char112 \char97 \char115 \char115 \thfc\char233 \mainfont{} etex,(-19.39,-11.53),0.0,0);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char50 \char54 \char48 \mainfont{} etex,(14.84,-1.58),0.0,1);
endfig;
background:=(0.25000,0.40000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.40000, 1.00000);
current_scrap := "D35_20160913_SP10@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP10";
background:=(0.25000,0.56500,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.56500, 1.00000);
current_scrap := "D35_20160913_SP9@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP9";
beginfig(161);
draw_upscrap(1)(1,((2.62,42.90)
 .. controls (2.62,42.90) and (8.46,45.50) .. (9.89,43.52)
 .. controls (10.54,42.63) and (12.23,40.09) .. (12.51,39.62)
 .. controls (12.80,39.16) and (13.85,37.56) .. (14.25,36.57)
 .. controls (14.65,35.58) and (16.55,33.93) .. (16.59,33.69)
 .. controls (16.63,33.45) and (17.04,33.99) .. (17.15,33.77)
 .. controls (17.26,33.54) and (17.11,34.58) .. (16.95,35.10)
 .. controls (16.78,35.63) and (18.23,38.83) .. (18.30,39.98)
 .. controls (18.37,41.11) and (18.62,42.93) .. (18.98,43.34)
),
1,((18.98,43.34)
 .. controls (18.98,43.34) and (19.57,44.92) .. (20.61,44.78)
),
1,((8.69,59.06)
 .. controls (8.84,57.55) and (7.31,58.24) .. (6.90,58.08)
 .. controls (6.47,57.91) and (4.66,58.75) .. (4.66,58.75)
),
1,((4.66,58.75)
 .. controls (4.08,59.09) and (4.14,58.54) .. (3.79,58.27)
 .. controls (3.44,58.01) and (3.18,58.25) .. (2.88,58.54)
 .. controls (2.58,58.83) and (2.41,59.37) .. (2.42,59.19)
 .. controls (2.43,59.01) and (2.72,58.60) .. (2.44,58.25)
 .. controls (2.15,57.90) and (2.18,57.47) .. (2.43,56.58)
 .. controls (2.68,55.69) and (2.08,54.53) .. (2.19,53.03)
 .. controls (2.30,51.54) and (1.81,50.37) .. (1.81,50.37)
));
draw_downscrap;
endfig;
beginfig(162);
ATTR__survey := "D35_20160913.D35projet";
ATTR__height := -1;
drawoptions();
l_pit(((2.61,49.94)
 .. controls (2.61,49.94) and (2.20,49.06) .. (1.99,48.54)
 .. controls (1.78,48.02) and (1.64,46.51) .. (2.31,46.48)
 .. controls (2.99,46.46) and (4.96,46.47) .. (5.60,46.11)
 .. controls (6.24,45.74) and (7.59,45.64) .. (8.47,45.25)
 .. controls (9.36,44.85) and (11.15,43.48) .. (11.60,42.66)
 .. controls (12.05,41.85) and (13.58,39.42) .. (13.67,39.28)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((12.58,37.11)
 -- (12.28,-25.92)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((12.28,-25.92)
 -- (-20.61,-57.08)
));
ATTR__height := -1;
drawoptions();
l_pit(((9.93,57.52)
 .. controls (9.81,54.08) and (5.60,57.69) .. (4.22,57.74)
 .. controls (2.75,57.79) and (3.78,56.42) .. (3.29,55.26)
 .. controls (2.80,54.10) and (3.09,52.69) .. (3.03,51.95)
 .. controls (2.96,51.20) and (2.61,49.94) .. (2.61,49.94)
));
ATTR__height := -1;
drawoptions();
l_pit(((13.67,39.28)
 .. controls (13.67,39.28) and (15.76,35.90) .. (16.25,38.74)
 .. controls (16.73,41.51) and (16.68,41.59) .. (16.89,42.97)
 .. controls (17.11,44.37) and (16.72,45.77) .. (18.76,45.86)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.66,58.75)
 .. controls (4.08,59.09) and (4.14,58.54) .. (3.79,58.27)
 .. controls (3.44,58.01) and (3.18,58.25) .. (2.88,58.54)
 .. controls (2.58,58.83) and (2.41,59.37) .. (2.42,59.19)
 .. controls (2.43,59.01) and (2.72,58.60) .. (2.44,58.25)
 .. controls (2.15,57.90) and (2.18,57.47) .. (2.43,56.58)
 .. controls (2.68,55.69) and (2.08,54.53) .. (2.19,53.03)
 .. controls (2.30,51.54) and (1.81,50.37) .. (1.81,50.37)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((8.69,59.06)
 .. controls (8.84,57.55) and (7.31,58.24) .. (6.90,58.08)
 .. controls (6.47,57.91) and (4.66,58.75) .. (4.66,58.75)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2.62,42.90)
 .. controls (2.62,42.90) and (8.46,45.50) .. (9.89,43.52)
 .. controls (10.54,42.63) and (12.23,40.09) .. (12.51,39.62)
 .. controls (12.80,39.16) and (13.85,37.56) .. (14.25,36.57)
 .. controls (14.65,35.58) and (16.55,33.93) .. (16.59,33.69)
 .. controls (16.63,33.45) and (17.04,33.99) .. (17.15,33.77)
 .. controls (17.26,33.54) and (17.11,34.58) .. (16.95,35.10)
 .. controls (16.78,35.63) and (18.23,38.83) .. (18.30,39.98)
 .. controls (18.37,41.11) and (18.62,42.93) .. (18.98,43.34)
));
drawoptions();
p_airdraught_summer((6.13,40.97),101.2,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((18.98,43.34)
 .. controls (18.98,43.34) and (19.57,44.92) .. (20.61,44.78)
));
endfig;
beginfig(163);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char100 \char117 \ \char99 \char111 \char108 \char108 \char101 \char99 \char116 \char101 \char117 \char114 \char58 \ \ \char80 \char52 \char55 \mainfont{} etex,(-20.50,-59.37),0.0,0);
endfig;
background:=(0.25000,1.00000,0.81250);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.81250);
current_scrap := "D35_20160913_SP5@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP5";
beginfig(164);
ATTR__height := -1;
drawoptions();
l_pit(((7.11,12.00)
 .. controls (7.90,11.93) and (7.36,12.36) .. (7.96,12.74)
 .. controls (8.57,13.13) and (8.46,15.38) .. (8.24,15.83)
 .. controls (8.01,16.28) and (6.84,17.13) .. (6.84,17.13)
));
ATTR__height := -1;
drawoptions();
l_pit(((13.68,17.94)
 .. controls (13.68,17.94) and (13.18,18.14) .. (13.12,19.22)
 .. controls (13.05,20.30) and (10.24,20.86) .. (10.10,19.72)
 .. controls (9.97,18.57) and (9.70,18.07) .. (9.65,17.53)
 .. controls (9.61,16.99) and (9.49,15.51) .. (9.45,14.84)
 .. controls (9.40,14.16) and (9.61,11.93) .. (9.65,10.72)
 .. controls (9.70,9.50) and (9.29,8.87) .. (9.16,8.20)
 .. controls (9.02,7.52) and (8.66,5.97) .. (8.77,5.18)
 .. controls (8.89,4.40) and (9.11,1.99) .. (9.90,0.55)
 .. controls (10.69,-0.89) and (11.14,-2.55) .. (12.53,-2.46)
 .. controls (13.93,-2.37) and (16.51,0.15) .. (17.23,1.04)
));
ATTR__height := -1;
drawoptions();
l_pit(((17.23,1.04)
 .. controls (17.23,1.04) and (17.62,2.06) .. (17.73,2.87)
 .. controls (17.84,3.68) and (19.35,4.40) .. (19.93,4.58)
 .. controls (20.52,4.76) and (21.60,5.63) .. (22.16,5.99)
 .. controls (22.72,6.35) and (23.06,7.30) .. (23.62,8.33)
 .. controls (24.18,9.37) and (23.22,11.35) .. (22.74,12.18)
 .. controls (22.27,13.01) and (21.08,13.66) .. (20.45,13.98)
 .. controls (19.82,14.29) and (18.16,15.28) .. (17.35,16.25)
 .. controls (16.54,17.22) and (16.31,16.93) .. (14.89,17.33)
 .. controls (13.48,17.74) and (13.68,17.94) .. (13.68,17.94)
));
endfig;
beginfig(165);
draw_upscrap(1)(1,((9.81,39.27)
 .. controls (9.81,39.27) and (8.01,38.03) .. (7.83,36.86)
 .. controls (7.65,35.69) and (7.70,35.33) .. (7.90,34.63)
 .. controls (8.10,33.94) and (7.92,33.33) .. (7.92,32.83)
 .. controls (7.92,32.34) and (8.44,26.87) .. (8.73,26.29)
 .. controls (9.02,25.70) and (9.02,22.62) .. (8.71,21.13)
 .. controls (8.39,19.65) and (9.11,18.82) .. (9.25,18.05)
 .. controls (9.29,17.81) and (9.18,16.34) .. (9.20,15.82)
),
1,((9.20,15.82)
 .. controls (9.20,15.82) and (9.16,15.38) .. (8.80,15.65)
 .. controls (8.44,15.92) and (8.30,16.10) .. (8.19,16.30)
 .. controls (8.08,16.50) and (7.88,16.90) .. (7.88,16.90)
),
1,((7.88,16.90)
 .. controls (7.63,17.47) and (6.48,17.83) .. (4.19,18.05)
 .. controls (1.89,18.28) and (1.31,12.38) .. (-0.02,7.52)
 .. controls (-1.35,2.66) and (4.66,-2.96) .. (5.76,-3.32)
 .. controls (6.86,-3.68) and (10.30,-3.07) .. (10.30,-3.07)
),
1,((10.30,-3.07)
 .. controls (12.08,-2.85) and (11.53,-3.53) .. (12.51,-3.54)
 .. controls (14.31,-3.57) and (17.03,-1.32) .. (17.71,0.51)
 .. controls (18.38,2.33) and (18.31,3.02) .. (19.64,3.68)
 .. controls (20.97,4.33) and (20.79,4.01) .. (21.66,4.96)
 .. controls (22.54,5.90) and (24.48,7.03) .. (24.52,8.60)
 .. controls (24.57,10.18) and (23.80,12.74) .. (22.09,13.98)
 .. controls (20.38,15.22) and (18.34,15.40) .. (17.44,16.90)
),
1,((17.44,16.90)
 .. controls (16.94,17.83) and (14.33,17.67) .. (13.84,18.19)
 .. controls (13.34,18.70) and (15.41,25.61) .. (15.39,26.58)
 .. controls (15.37,27.55) and (15.93,28.31) .. (15.93,28.31)
),
1,((15.93,28.31)
 .. controls (16.09,28.51) and (16.63,29.75) .. (17.01,30.13)
 .. controls (17.39,30.52) and (19.42,33.42) .. (19.98,33.91)
 .. controls (20.54,34.41) and (21.20,37.96) .. (21.20,37.96)
));
draw_upscrap(1)(1,((7.87,-1.43)
 .. controls (6.01,-0.69) and (5.53,6.98) .. (5.42,8.38)
 .. controls (5.31,9.77) and (6.23,11.78) .. (6.88,11.60)
 .. controls (7.54,11.42) and (7.83,11.80) .. (7.83,11.80)
),
1,((7.83,11.80)
 .. controls (7.83,11.80) and (7.99,11.93) .. (8.10,12.47)
 .. controls (8.21,13.01) and (8.68,12.97) .. (8.84,13.04)
 .. controls (9.00,13.10) and (9.04,12.36) .. (9.04,12.36)
),
1,((9.04,12.36)
 .. controls (9.07,11.84) and (9.27,10.00) .. (8.80,8.74)
 .. controls (8.32,7.48) and (7.76,3.11) .. (8.50,1.81)
),
1,((8.50,1.81)
 .. controls (8.50,1.81) and (9.02,1.20) .. (9.20,0.39)
 .. controls (9.38,-0.42) and (9.90,-0.60) .. (9.72,-1.07)
 .. controls (9.54,-1.54) and (8.10,-1.54) .. (7.87,-1.43)
));
draw_downscrap;
endfig;
beginfig(166);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((17.44,16.90)
 .. controls (16.94,17.83) and (14.33,17.67) .. (13.84,18.19)
 .. controls (13.34,18.70) and (15.41,25.61) .. (15.39,26.58)
 .. controls (15.37,27.55) and (15.93,28.31) .. (15.93,28.31)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((15.93,28.31)
 .. controls (16.09,28.51) and (16.63,29.75) .. (17.01,30.13)
 .. controls (17.39,30.52) and (19.42,33.42) .. (19.98,33.91)
 .. controls (20.54,34.41) and (21.20,37.96) .. (21.20,37.96)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((10.30,-3.07)
 .. controls (12.08,-2.85) and (11.53,-3.53) .. (12.51,-3.54)
 .. controls (14.31,-3.57) and (17.03,-1.32) .. (17.71,0.51)
 .. controls (18.38,2.33) and (18.31,3.02) .. (19.64,3.68)
 .. controls (20.97,4.33) and (20.79,4.01) .. (21.66,4.96)
 .. controls (22.54,5.90) and (24.48,7.03) .. (24.52,8.60)
 .. controls (24.57,10.18) and (23.80,12.74) .. (22.09,13.98)
 .. controls (20.38,15.22) and (18.34,15.40) .. (17.44,16.90)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((9.04,12.36)
 .. controls (9.07,11.84) and (9.27,10.00) .. (8.80,8.74)
 .. controls (8.32,7.48) and (7.76,3.11) .. (8.50,1.81)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((8.50,1.81)
 .. controls (8.50,1.81) and (9.02,1.20) .. (9.20,0.39)
 .. controls (9.38,-0.42) and (9.90,-0.60) .. (9.72,-1.07)
 .. controls (9.54,-1.54) and (8.10,-1.54) .. (7.87,-1.43)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((7.88,16.90)
 .. controls (7.63,17.47) and (6.48,17.83) .. (4.19,18.05)
 .. controls (1.89,18.28) and (1.31,12.38) .. (-0.02,7.52)
));
drawoptions();
l_wall_bedrock(((-0.02,7.52)
 .. controls (-1.35,2.66) and (4.66,-2.96) .. (5.76,-3.32)
 .. controls (6.86,-3.68) and (10.30,-3.07) .. (10.30,-3.07)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((3.37,-3.09)
 -- (-11.07,-17.72)
 -- (-22.99,-17.67)
));
ATTR__height := -1;
drawoptions();
l_wall_presumed(((7.87,-1.43)
 .. controls (6.01,-0.69) and (5.53,6.98) .. (5.42,8.38)
));
drawoptions();
l_wall_bedrock(((5.42,8.38)
 .. controls (5.31,9.77) and (6.23,11.78) .. (6.88,11.60)
 .. controls (7.54,11.42) and (7.83,11.80) .. (7.83,11.80)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((9.81,39.27)
 .. controls (9.81,39.27) and (8.01,38.03) .. (7.83,36.86)
 .. controls (7.65,35.69) and (7.70,35.33) .. (7.90,34.63)
 .. controls (8.10,33.94) and (7.92,33.33) .. (7.92,32.83)
 .. controls (7.92,32.34) and (8.44,26.87) .. (8.73,26.29)
 .. controls (9.02,25.70) and (9.02,22.62) .. (8.71,21.13)
 .. controls (8.39,19.65) and (9.11,18.82) .. (9.25,18.05)
 .. controls (9.29,17.81) and (9.18,16.34) .. (9.20,15.82)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((9.20,15.82)
 .. controls (9.20,15.82) and (9.16,15.38) .. (8.80,15.65)
 .. controls (8.44,15.92) and (8.30,16.10) .. (8.19,16.30)
 .. controls (8.08,16.50) and (7.88,16.90) .. (7.88,16.90)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((7.83,11.80)
 .. controls (7.83,11.80) and (7.99,11.93) .. (8.10,12.47)
 .. controls (8.21,13.01) and (8.68,12.97) .. (8.84,13.04)
 .. controls (9.00,13.10) and (9.04,12.36) .. (9.04,12.36)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((19.73,2.78)
 -- (19.75,-26.09)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((19.75,-26.09)
 -- (7.83,-37.38)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((7.65,17.65)
 -- (3.11,22.30)
 -- (-2.43,22.31)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-2.43,22.31)
 -- (-9.49,15.11)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-9.49,15.11)
 -- (-9.54,-0.75)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-22.90,-9.26)
 -- (-11.20,-9.17)
 -- (-9.54,-7.41)
 -- (-9.54,-0.75)
));
endfig;
beginfig(167);
drawoptions();
p_label.rt(btex \thaltitude \thfb\char49 \char49 \char52 \char56 \mainfont{} etex,(14.78,23.52),0.0,1);
drawoptions();
p_label.bot(btex \thaltitude \thfb\char49 \char49 \char49 \char50 \mainfont{} etex,(12.24,-3.50),0.0,1);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char112 \char97 \char114 \char97 \char108 \char108 \accent18 \char101 \char108 \char101 \ \char110 \char111 \char110 \ \char101 \char120 \char112 \char108 \char111 \char114 \thfc\char233 \mainfont{} etex,(-24.57,-17.63),0.0,0);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char75 \char105 \char107 \char105 \char58 \ \char80 \char54 \char57 \mainfont{} etex,(7.83,-39.27),0.0,0);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char76 \char117 \char99 \char97 \char114 \char110 \char101 \ \mainfont{} etex,(-24.41,-9.19),0.0,0);
endfig;
background:=(0.25000,1.00000,0.62500);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.62500);
current_scrap := "D35_20160913_SP4@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP4";
beginfig(168);
ATTR__height := -1;
drawoptions();
l_pit(((2.62,2.90)
 .. controls (2.62,3.22) and (2.44,3.96) .. (2.28,4.77)
 .. controls (2.13,5.58) and (2.06,7.94) .. (2.13,8.55)
 .. controls (2.19,9.16) and (2.76,9.29) .. (3.05,10.10)
 .. controls (3.34,10.91) and (2.35,10.80) .. (1.52,11.68)
 .. controls (0.69,12.56) and (-0.71,13.19) .. (-0.77,11.16)
));
ATTR__height := -1;
drawoptions();
l_pit(((-0.77,11.16)
 .. controls (-0.77,11.16) and (-0.75,10.96) .. (-0.78,9.72)
 .. controls (-0.80,8.48) and (-1.65,7.70) .. (-2.10,7.02)
 .. controls (-2.55,6.35) and (-5.10,4.75) .. (-5.10,4.75)
));
endfig;
beginfig(169);
draw_upscrap(1)(1,((2.17,-0.36)
 .. controls (2.17,-0.36) and (3.05,0.85) .. (3.12,1.87)
 .. controls (3.18,2.88) and (2.60,5.67) .. (2.49,6.39)
 .. controls (2.37,7.11) and (2.37,8.15) .. (2.80,8.93)
 .. controls (3.23,9.72) and (3.63,9.56) .. (3.63,10.58)
 .. controls (3.64,11.59) and (1.56,14.24) .. (1.48,15.39)
),
1,((-1.40,13.39)
 .. controls (-1.40,13.39) and (-1.02,12.58) .. (-1.02,12.26)
 .. controls (-1.02,11.95) and (-0.96,9.38) .. (-1.16,8.89)
 .. controls (-1.36,8.39) and (-3.45,6.48) .. (-3.79,6.21)
 .. controls (-4.13,5.94) and (-6.04,4.84) .. (-6.38,4.32)
 .. controls (-6.72,3.80) and (-8.07,2.39) .. (-8.18,2.21)
 .. controls (-8.29,2.03) and (-9.15,1.06) .. (-9.21,0.94)
));
draw_downscrap;
endfig;
beginfig(170);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1.40,13.39)
 .. controls (-1.40,13.39) and (-1.02,12.58) .. (-1.02,12.26)
 .. controls (-1.02,11.95) and (-0.96,9.38) .. (-1.16,8.89)
 .. controls (-1.36,8.39) and (-3.45,6.48) .. (-3.79,6.21)
 .. controls (-4.13,5.94) and (-6.04,4.84) .. (-6.38,4.32)
 .. controls (-6.72,3.80) and (-8.07,2.39) .. (-8.18,2.21)
 .. controls (-8.29,2.03) and (-9.15,1.06) .. (-9.21,0.94)
));
ATTR__height := -1;
drawoptions();
l_pit(((-5.10,4.75)
 .. controls (-5.10,4.75) and (-6.49,4.03) .. (-6.67,3.56)
 .. controls (-6.85,3.08) and (-7.30,2.70) .. (-7.48,2.48)
 .. controls (-7.66,2.25) and (-8.49,0.99) .. (-8.99,0.58)
 .. controls (-9.48,0.18) and (-10.47,-0.92) .. (-10.41,-1.73)
 .. controls (-10.34,-2.54) and (-10.27,-4.21) .. (-10.27,-4.39)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((3.41,-0.14)
 -- (10.47,-7.18)
 -- (10.47,-14.36)
));
ATTR__height := -1;
drawoptions();
l_pit(((-1.45,-6.23)
 .. controls (0.35,-4.14) and (0.98,-1.94) .. (1.18,-1.06)
 .. controls (1.38,-0.18) and (1.02,-0.18) .. (1.86,0.63)
 .. controls (2.69,1.44) and (2.62,2.90) .. (2.62,2.90)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2.17,-0.36)
 .. controls (2.17,-0.36) and (3.05,0.85) .. (3.12,1.87)
 .. controls (3.18,2.88) and (2.60,5.67) .. (2.49,6.39)
 .. controls (2.37,7.11) and (2.37,8.15) .. (2.80,8.93)
 .. controls (3.23,9.72) and (3.63,9.56) .. (3.63,10.58)
 .. controls (3.64,11.59) and (1.56,14.24) .. (1.48,15.39)
));
drawoptions();
p_airdraught_summer((3.95,13.86),23.1,1.00,(0,0));
endfig;
beginfig(171);
drawoptions();
p_label.bot(btex \thlabel\thnormalsize \thfb\char80 \char49 \char52 \mainfont{} etex,(10.45,-15.39),0.0,0);
endfig;
background:=(0.25000,1.00000,0.53500);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.53500);
current_scrap := "D35_20160913_SP3@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP3";
beginfig(172);
draw_upscrap(1)(1,((-4.57,7.36)
 .. controls (-5.35,6.86) and (-5.77,6.53) .. (-6.16,6.23)
 .. controls (-7.13,5.49) and (-6.79,5.08) .. (-7.09,4.57)
 .. controls (-7.38,4.05) and (-8.08,3.56) .. (-7.72,2.54)
 .. controls (-7.36,1.53) and (-6.70,-0.58) .. (-6.59,-1.12)
 .. controls (-6.48,-1.66) and (-5.63,-2.99) .. (-5.24,-3.08)
 .. controls (-4.86,-3.17) and (-3.47,-2.81) .. (-3.02,-3.28)
 .. controls (-2.57,-3.76) and (-1.55,-4.77) .. (-1.42,-5.53)
 .. controls (-1.28,-6.30) and (-1.01,-7.42) .. (-0.90,-7.83)
),
1,((1.98,-5.83)
 .. controls (1.80,-5.26) and (1.78,-3.94) .. (1.75,-3.33)
 .. controls (1.73,-2.72) and (1.89,-3.04) .. (2.41,-2.72)
 .. controls (2.92,-2.41) and (4.07,-2.52) .. (6.07,-2.27)
 .. controls (8.08,-2.03) and (7.60,-1.35) .. (7.42,0.18)
 .. controls (7.24,1.71) and (7.33,2.72) .. (7.40,3.10)
));
draw_downscrap;
endfig;
beginfig(173);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1.98,-5.83)
 .. controls (1.80,-5.26) and (1.78,-3.94) .. (1.75,-3.33)
 .. controls (1.73,-2.72) and (1.89,-3.04) .. (2.41,-2.72)
 .. controls (2.92,-2.41) and (4.07,-2.52) .. (6.07,-2.27)
 .. controls (8.08,-2.03) and (7.60,-1.35) .. (7.42,0.18)
 .. controls (7.24,1.71) and (7.33,2.72) .. (7.40,3.10)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.57,7.36)
 .. controls (-5.35,6.86) and (-5.77,6.53) .. (-6.16,6.23)
 .. controls (-7.13,5.49) and (-6.79,5.08) .. (-7.09,4.57)
 .. controls (-7.38,4.05) and (-8.08,3.56) .. (-7.72,2.54)
 .. controls (-7.36,1.53) and (-6.70,-0.58) .. (-6.59,-1.12)
 .. controls (-6.48,-1.66) and (-5.63,-2.99) .. (-5.24,-3.08)
 .. controls (-4.86,-3.17) and (-3.47,-2.81) .. (-3.02,-3.28)
 .. controls (-2.57,-3.76) and (-1.55,-4.77) .. (-1.42,-5.53)
 .. controls (-1.28,-6.30) and (-1.01,-7.42) .. (-0.90,-7.83)
));
ATTR__height := -1;
drawoptions();
l_pit(((-2.18,7.83)
 .. controls (-3.35,7.67) and (-5.06,6.55) .. (-5.87,5.60)
 .. controls (-6.68,4.66) and (-6.57,2.48) .. (-5.92,-0.34)
 .. controls (-5.27,-3.15) and (-2.79,-2.47) .. (-2.79,-2.47)
));
ATTR__height := -1;
drawoptions();
l_pit(((1.35,-2.41)
 .. controls (1.62,-2.16) and (1.64,-1.90) .. (3.87,-1.49)
 .. controls (7.22,-0.86) and (6.28,0.97) .. (6.16,1.87)
 .. controls (6.05,2.77) and (6.91,4.16) .. (7.22,5.47)
));
endfig;
beginfig(174);
drawoptions();
p_label.llft(btex \thaltitude \thfb\char49 \char49 \char54 \char53 \mainfont{} etex,(-2.66,-3.62),0.0,1);
endfig;
background:=(0.25000,1.00000,0.33250);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.33250);
current_scrap := "D35_20160913_SP1@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP1";
beginfig(175);
draw_upscrap(1)(1,((-13.68,-11.01)
 .. controls (-13.59,-10.72) and (-12.75,-8.02) .. (-12.76,-7.61)
 .. controls (-12.76,-7.21) and (-12.75,-6.21) .. (-12.58,-5.85)
 .. controls (-12.41,-5.49) and (-11.53,-2.66) .. (-11.53,-2.66)
),
1,((-11.53,-2.66)
 .. controls (-11.22,-1.05) and (-11.98,-0.66) .. (-12.18,0.90)
 .. controls (-12.38,2.48) and (-13.62,3.24) .. (-14.38,3.75)
 .. controls (-15.17,4.28) and (-17.22,4.67) .. (-17.22,4.67)
),
1,((-18.98,4.88)
 .. controls (-20.15,5.45) and (-21.26,3.44) .. (-21.72,2.29)
 .. controls (-22.17,1.13) and (-22.21,0.48) .. (-22.17,0.14)
 .. controls (-22.13,-0.20) and (-21.83,-1.16) .. (-22.18,-1.41)
),
1,((-22.18,-1.41)
 .. controls (-22.18,-1.41) and (-22.51,-1.65) .. (-22.57,-1.81)
 .. controls (-22.63,-1.97) and (-23.03,-2.24) .. (-22.88,-2.65)
 .. controls (-22.73,-3.06) and (-22.65,-3.87) .. (-22.87,-4.17)
 .. controls (-23.09,-4.46) and (-23.27,-5.41) .. (-23.70,-5.68)
),
1,((-23.70,-5.68)
 -- (-25.65,-6.76)
));
draw_downscrap;
endfig;
beginfig(176);
ATTR__height := -1;
drawoptions();
l_pit(((-13.86,-8.65)
 .. controls (-13.57,-7.34) and (-13.57,-6.37) .. (-13.04,-5.19)
 .. controls (-12.52,-4.01) and (-12.33,-2.48) .. (-12.40,-1.16)
 .. controls (-12.47,0.15) and (-13.06,1.13) .. (-15.18,2.88)
 .. controls (-17.46,4.78) and (-20.14,3.20) .. (-20.62,2.55)
 .. controls (-21.11,1.89) and (-21.32,0.57) .. (-21.35,-0.45)
 .. controls (-21.38,-1.47) and (-21.52,-1.48) .. (-21.83,-2.38)
 .. controls (-22.13,-3.29) and (-20.84,-3.63) .. (-21.10,-4.87)
 .. controls (-21.36,-6.11) and (-23.27,-6.29) .. (-23.27,-6.29)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-22.18,-1.41)
 .. controls (-22.18,-1.41) and (-22.51,-1.65) .. (-22.57,-1.81)
 .. controls (-22.63,-1.97) and (-23.03,-2.24) .. (-22.88,-2.65)
 .. controls (-22.73,-3.06) and (-22.65,-3.87) .. (-22.87,-4.17)
 .. controls (-23.09,-4.46) and (-23.27,-5.41) .. (-23.70,-5.68)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-23.70,-5.68)
 -- (-25.65,-6.76)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-13.68,-11.01)
 .. controls (-13.59,-10.72) and (-12.75,-8.02) .. (-12.76,-7.61)
 .. controls (-12.76,-7.21) and (-12.75,-6.21) .. (-12.58,-5.85)
 .. controls (-12.41,-5.49) and (-11.53,-2.66) .. (-11.53,-2.66)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-18.98,4.88)
 .. controls (-20.15,5.45) and (-21.26,3.44) .. (-21.72,2.29)
 .. controls (-22.17,1.13) and (-22.21,0.48) .. (-22.17,0.14)
 .. controls (-22.13,-0.20) and (-21.83,-1.16) .. (-22.18,-1.41)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.53,-2.66)
 .. controls (-11.22,-1.05) and (-11.98,-0.66) .. (-12.18,0.90)
 .. controls (-12.38,2.48) and (-13.62,3.24) .. (-14.38,3.75)
 .. controls (-15.17,4.28) and (-17.22,4.67) .. (-17.22,4.67)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-2.35,0.04)
 -- (8.27,11.00)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((8.27,11.00)
 -- (24.82,10.99)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-12.41,-10.43)
 -- (-9.38,-7.08)
));
endfig;
beginfig(177);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char117 \char105 \char116 \char115 \ \char100 \char117 \ \char112 \char97 \char114 \char105 \char58 \ \char80 \char52 \char50 \mainfont{} etex,(25.65,11.01),0.0,0);
endfig;
background:=(0.25000,0.73000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.73000, 1.00000);
current_scrap := "D35_20160913_SP8@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP8";
beginfig(178);
draw_upscrap(1)(1,((-2.06,-6.47)
 .. controls (-2.06,-6.47) and (-1.07,-6.38) .. (0.44,-5.21)
 .. controls (1.95,-4.04) and (1.95,-2.76) .. (2.85,-2.31)
 .. controls (3.32,-2.07) and (3.18,-1.68) .. (3.70,-1.54)
),
1,reverse ((-3.70,3.63)
 .. controls (-3.70,3.63) and (-1.11,3.72) .. (-0.28,4.08)
 .. controls (0.55,4.44) and (2.33,4.26) .. (2.67,4.78)
 .. controls (3.00,5.30) and (2.80,5.75) .. (2.89,5.93)
));
draw_downscrap;
endfig;
beginfig(179);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2.06,-6.47)
 .. controls (-2.06,-6.47) and (-1.07,-6.38) .. (0.44,-5.21)
 .. controls (1.95,-4.04) and (1.95,-2.76) .. (2.85,-2.31)
 .. controls (3.32,-2.07) and (3.18,-1.68) .. (3.70,-1.54)
));
drawoptions();
p_airdraught_summer((-0.42,6.47),101.2,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.70,3.63)
 .. controls (-3.70,3.63) and (-1.11,3.72) .. (-0.28,4.08)
 .. controls (0.55,4.44) and (2.33,4.26) .. (2.67,4.78)
 .. controls (3.00,5.30) and (2.80,5.75) .. (2.89,5.93)
));
endfig;
beginfig(180);
drawoptions();
p_label.lrt(btex \thaltitude \thfb\char49 \char48 \char54 \char55 \mainfont{} etex,(2.53,-2.53),0.0,1);
endfig;
background:=(0.25000,0.87250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.87250, 1.00000);
current_scrap := "D35_20160913_SP7@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP7";
beginfig(181);
draw_upscrap(1)(1,((-7.18,14.53)
 .. controls (-6.62,12.76) and (-6.01,13.43) .. (-5.58,12.33)
 .. controls (-5.15,11.23) and (-3.94,9.43) .. (-4.32,7.24)
 .. controls (-4.70,5.06) and (-10.35,-2.72) .. (-10.35,-2.72)
),
1,((-3.15,-6.64)
 .. controls (-3.15,-6.64) and (-0.36,-3.08) .. (0.43,-1.55)
 .. controls (1.21,-0.02) and (-0.09,1.08) .. (0.27,1.96)
 .. controls (0.63,2.84) and (2.90,2.88) .. (4.16,1.71)
 .. controls (5.42,0.54) and (5.71,0.54) .. (6.25,0.36)
),
1,((4.61,10.46)
 .. controls (3.89,10.44) and (2.72,10.13) .. (1.89,10.94)
 .. controls (1.06,11.75) and (-5.11,15.65) .. (-6.23,16.13)
),
1,((-6.23,16.13)
 .. controls (-6.23,16.13) and (-6.55,16.29) .. (-6.91,16.34)
 .. controls (-7.27,16.38) and (-7.54,16.56) .. (-7.70,16.63)
),
1,((-8.19,15.37)
 .. controls (-8.19,15.37) and (-7.43,15.07) .. (-7.18,14.53)
));
draw_downscrap;
endfig;
beginfig(182);
ATTR__height := -1;
drawoptions();
l_pit(((7.67,10.04)
 .. controls (7.49,9.97) and (6.95,9.77) .. (6.07,9.56)
 .. controls (5.20,9.36) and (3.42,8.60) .. (2.59,9.63)
 .. controls (1.75,10.67) and (0.70,11.14) .. (-0.25,10.71)
 .. controls (-1.19,10.28) and (-0.77,8.82) .. (0.81,5.90)
 .. controls (2.38,2.97) and (5.92,1.80) .. (5.92,1.80)
));
ATTR__height := -1;
drawoptions();
l_pit(((5.92,1.80)
 .. controls (5.92,1.80) and (7.33,0.79) .. (8.80,2.70)
 .. controls (10.26,4.61) and (10.35,5.15) .. (10.35,5.15)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.15,-6.64)
 .. controls (-3.15,-6.64) and (-0.36,-3.08) .. (0.43,-1.55)
 .. controls (1.21,-0.02) and (-0.09,1.08) .. (0.27,1.96)
 .. controls (0.63,2.84) and (2.90,2.88) .. (4.16,1.71)
 .. controls (5.42,0.54) and (5.71,0.54) .. (6.25,0.36)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((5.58,0.27)
 -- (5.58,-14.96)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.61,10.46)
 .. controls (3.89,10.44) and (2.72,10.13) .. (1.89,10.94)
 .. controls (1.06,11.75) and (-5.11,15.65) .. (-6.23,16.13)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-6.23,16.13)
 .. controls (-6.23,16.13) and (-6.55,16.29) .. (-6.91,16.34)
 .. controls (-7.27,16.38) and (-7.54,16.56) .. (-7.70,16.63)
));
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((-9.23,16.36),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.18,14.53)
 .. controls (-6.62,12.76) and (-6.01,13.43) .. (-5.58,12.33)
 .. controls (-5.15,11.23) and (-3.94,9.43) .. (-4.32,7.24)
 .. controls (-4.70,5.06) and (-10.35,-2.72) .. (-10.35,-2.72)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-8.19,15.37)
 .. controls (-8.19,15.37) and (-7.43,15.07) .. (-7.18,14.53)
));
endfig;
beginfig(183);
drawoptions();
p_label.bot(btex \thlabel\thnormalsize \thfb\char80 \char49 \char53 \mainfont{} etex,(5.60,-16.63),0.0,0);
endfig;
background:=(0.25000,1.00000,0.99250);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.99250);
current_scrap := "D35_20160913_SP6@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP6";
beginfig(184);
ATTR__height := -1;
drawoptions();
l_pit(((-54.99,-6.16)
 .. controls (-55.02,-5.95) and (-56.21,-5.84) .. (-56.73,-3.79)
 .. controls (-57.24,-1.75) and (-57.72,-1.36) .. (-58.50,-0.60)
 .. controls (-59.29,0.17) and (-59.58,0.93) .. (-59.58,0.93)
));
endfig;
beginfig(185);
draw_upscrap(1)(1,((-63.25,-10.27)
 .. controls (-63.25,-10.27) and (-64.17,-7.57) .. (-62.94,-4.85)
 .. controls (-61.70,-2.13) and (-61.93,-0.01) .. (-62.15,1.13)
 .. controls (-62.38,2.28) and (-62.80,3.52) .. (-63.25,4.64)
 .. controls (-63.70,5.77) and (-65.39,9.10) .. (-66.25,11.19)
 .. controls (-67.10,13.28) and (-67.82,14.93) .. (-67.30,16.43)
 .. controls (-66.79,17.94) and (-65.98,21.25) .. (-64.94,21.45)
),
1,reverse ((-62.87,22.51)
 .. controls (-63.82,21.54) and (-64.94,21.45) .. (-64.94,21.45)
),
1,reverse ((-52.11,-8.41)
 .. controls (-52.11,-8.41) and (-51.01,-8.18) .. (-50.49,-6.83)
 .. controls (-49.98,-5.48) and (-50.07,-5.71) .. (-50.13,-4.40)
 .. controls (-50.20,-3.10) and (-50.85,-1.54) .. (-51.21,-0.89)
 .. controls (-51.57,-0.24) and (-52.02,0.84) .. (-53.51,0.89)
 .. controls (-54.99,0.93) and (-56.66,0.23) .. (-57.56,0.23)
 .. controls (-58.46,0.23) and (-59.52,1.18) .. (-59.67,1.88)
 .. controls (-59.83,2.57) and (-60.06,3.74) .. (-60.51,4.24)
 .. controls (-60.96,4.73) and (-61.41,4.80) .. (-61.48,5.39)
 .. controls (-61.54,5.97) and (-61.72,7.32) .. (-60.91,7.88)
 .. controls (-60.10,8.45) and (-58.57,8.31) .. (-58.08,9.26)
 .. controls (-57.58,10.20) and (-56.93,11.69) .. (-57.22,13.42)
 .. controls (-57.52,15.15) and (-56.32,18.14) .. (-55.67,18.59)
),
1,reverse ((-63.25,-10.27)
 .. controls (-63.16,-10.45) and (-62.10,-11.82) .. (-61.92,-12.21)
 .. controls (-60.35,-15.79) and (-54.88,-13.83) .. (-54.25,-11.40)
 .. controls (-53.62,-8.97) and (-52.11,-8.41) .. (-52.11,-8.41)
));
draw_downscrap;
endfig;
beginfig(186);
drawoptions(withcolor (0.000000,0.000000,0.000000));
p_waterflow_permanent((-63.21,17.00),334.1,1.00,(0,0));
drawoptions(withcolor (0.000000,0.000000,0.000000));
p_spring((-64.02,14.93),336.4,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((-67.57,17.81)
 -- (-86.16,17.81)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-63.25,-10.27)
 .. controls (-63.25,-10.27) and (-64.17,-7.57) .. (-62.94,-4.85)
 .. controls (-61.70,-2.13) and (-61.93,-0.01) .. (-62.15,1.13)
 .. controls (-62.38,2.28) and (-62.80,3.52) .. (-63.25,4.64)
 .. controls (-63.70,5.77) and (-65.39,9.10) .. (-66.25,11.19)
 .. controls (-67.10,13.28) and (-67.82,14.93) .. (-67.30,16.43)
 .. controls (-66.79,17.94) and (-65.98,21.25) .. (-64.94,21.45)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-62.87,22.51)
 .. controls (-63.82,21.54) and (-64.94,21.45) .. (-64.94,21.45)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-52.11,-8.41)
 .. controls (-52.11,-8.41) and (-51.01,-8.18) .. (-50.49,-6.83)
 .. controls (-49.98,-5.48) and (-50.07,-5.71) .. (-50.13,-4.40)
 .. controls (-50.20,-3.10) and (-50.85,-1.54) .. (-51.21,-0.89)
 .. controls (-51.57,-0.24) and (-52.02,0.84) .. (-53.51,0.89)
 .. controls (-54.99,0.93) and (-56.66,0.23) .. (-57.56,0.23)
 .. controls (-58.46,0.23) and (-59.52,1.18) .. (-59.67,1.88)
 .. controls (-59.83,2.57) and (-60.06,3.74) .. (-60.51,4.24)
 .. controls (-60.96,4.73) and (-61.41,4.80) .. (-61.48,5.39)
 .. controls (-61.54,5.97) and (-61.72,7.32) .. (-60.91,7.88)
 .. controls (-60.10,8.45) and (-58.57,8.31) .. (-58.08,9.26)
 .. controls (-57.58,10.20) and (-56.93,11.69) .. (-57.22,13.42)
 .. controls (-57.52,15.15) and (-56.32,18.14) .. (-55.67,18.59)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-63.25,-10.27)
 .. controls (-63.16,-10.45) and (-62.10,-11.82) .. (-61.92,-12.21)
 .. controls (-60.35,-15.79) and (-54.88,-13.83) .. (-54.25,-11.40)
 .. controls (-53.62,-8.97) and (-52.11,-8.41) .. (-52.11,-8.41)
));
ATTR__height := -1;
drawoptions();
l_pit(((-61.61,0.30)
 .. controls (-61.43,-0.58) and (-61.61,-3.55) .. (-62.42,-5.05)
 .. controls (-63.23,-6.56) and (-62.80,-7.48) .. (-62.67,-9.42)
 .. controls (-62.53,-11.35) and (-60.12,-12.19) .. (-58.14,-12.28)
 .. controls (-56.16,-12.37) and (-55.13,-10.77) .. (-53.89,-8.79)
 .. controls (-53.03,-7.41) and (-54.99,-6.16) .. (-54.99,-6.16)
));
ATTR__height := -1;
drawoptions();
l_mapconnection(((-54.93,-15.81)
 -- (-54.93,-35.07)
 -- (88.01,-35.16)
 -- (88.00,-15.98)
));
ATTR__height := -1;
drawoptions();
l_pit(((-64.47,20.21)
 .. controls (-64.98,19.74) and (-65.55,19.43) .. (-65.86,18.80)
 .. controls (-66.18,18.17) and (-67.44,15.83) .. (-66.88,14.14)
 .. controls (-66.31,12.45) and (-64.74,8.67) .. (-64.22,8.36)
 .. controls (-63.70,8.04) and (-62.47,8.02) .. (-61.03,9.01)
 .. controls (-59.59,10.00) and (-58.48,9.08) .. (-58.28,11.42)
 .. controls (-58.08,13.76) and (-57.72,17.51) .. (-57.29,18.35)
 .. controls (-56.86,19.18) and (-54.32,21.43) .. (-54.21,22.82)
));
ATTR__height := -1;
drawoptions();
l_pit(((-56.73,35.16)
 .. controls (-56.57,34.84) and (-56.30,34.19) .. (-56.30,33.20)
 .. controls (-56.30,32.21) and (-57.88,29.10) .. (-58.30,28.34)
 .. controls (-58.73,27.57) and (-61.43,23.27) .. (-61.84,22.55)
 .. controls (-62.24,21.83) and (-64.47,20.21) .. (-64.47,20.21)
));
ATTR__height := -1;
drawoptions();
l_pit(((-54.21,22.82)
 .. controls (-54.21,22.82) and (-54.01,23.88) .. (-53.58,25.84)
 .. controls (-53.15,27.80) and (-52.72,28.18) .. (-52.36,28.47)
));
endfig;
beginfig(187);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char80 \char101 \char116 \char105 \char116 \ \char97 \char99 \char116 \char105 \char102 \ \char97 \char114 \char114 \char105 \char118 \thfc\char233 \thfb\char101 \ \char112 \char108 \char97 \char102 \char111 \char110 \char100 \mainfont{} etex,(-88.01,18.17),0.0,0);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char49 \char49 \char49 \mainfont{} etex,(-61.99,-0.60),0.0,1);
endfig;
background:=(0.25000,0.73000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.73000, 1.00000);
current_scrap := "D35_20160913_SP8@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP8";
beginfig(188);
draw_upscrap(1)(1,((-2.06,-6.47)
 .. controls (-2.06,-6.47) and (-1.07,-6.38) .. (0.44,-5.21)
 .. controls (1.95,-4.04) and (1.95,-2.76) .. (2.85,-2.31)
 .. controls (3.32,-2.07) and (3.18,-1.68) .. (3.70,-1.54)
),
1,reverse ((-3.70,3.63)
 .. controls (-3.70,3.63) and (-1.11,3.72) .. (-0.28,4.08)
 .. controls (0.55,4.44) and (2.33,4.26) .. (2.67,4.78)
 .. controls (3.00,5.30) and (2.80,5.75) .. (2.89,5.93)
));
draw_downscrap;
endfig;
background:=(0.25000,0.87250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.87250, 1.00000);
current_scrap := "D35_20160913_SP7@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP7";
beginfig(189);
draw_upscrap(1)(1,((-7.18,14.53)
 .. controls (-6.62,12.76) and (-6.01,13.43) .. (-5.58,12.33)
 .. controls (-5.15,11.23) and (-3.94,9.43) .. (-4.32,7.24)
 .. controls (-4.70,5.06) and (-10.35,-2.72) .. (-10.35,-2.72)
),
1,((-3.15,-6.64)
 .. controls (-3.15,-6.64) and (-0.36,-3.08) .. (0.43,-1.55)
 .. controls (1.21,-0.02) and (-0.09,1.08) .. (0.27,1.96)
 .. controls (0.63,2.84) and (2.90,2.88) .. (4.16,1.71)
 .. controls (5.42,0.54) and (5.71,0.54) .. (6.25,0.36)
),
1,((4.61,10.46)
 .. controls (3.89,10.44) and (2.72,10.13) .. (1.89,10.94)
 .. controls (1.06,11.75) and (-5.11,15.65) .. (-6.23,16.13)
),
1,((-6.23,16.13)
 .. controls (-6.23,16.13) and (-6.55,16.29) .. (-6.91,16.34)
 .. controls (-7.27,16.38) and (-7.54,16.56) .. (-7.70,16.63)
),
1,((-8.19,15.37)
 .. controls (-8.19,15.37) and (-7.43,15.07) .. (-7.18,14.53)
));
draw_downscrap;
endfig;
background:=(0.25000,1.00000,0.99250);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.99250);
current_scrap := "D35_20160913_SP6@D35_20160913.D35projet";
ATTR__scrap := "D35_20160913_SP6";
beginfig(190);
draw_upscrap(1)(1,((-63.25,-10.27)
 .. controls (-63.25,-10.27) and (-64.17,-7.57) .. (-62.94,-4.85)
 .. controls (-61.70,-2.13) and (-61.93,-0.01) .. (-62.15,1.13)
 .. controls (-62.38,2.28) and (-62.80,3.52) .. (-63.25,4.64)
 .. controls (-63.70,5.77) and (-65.39,9.10) .. (-66.25,11.19)
 .. controls (-67.10,13.28) and (-67.82,14.93) .. (-67.30,16.43)
 .. controls (-66.79,17.94) and (-65.98,21.25) .. (-64.94,21.45)
),
1,reverse ((-62.87,22.51)
 .. controls (-63.82,21.54) and (-64.94,21.45) .. (-64.94,21.45)
),
1,reverse ((-52.11,-8.41)
 .. controls (-52.11,-8.41) and (-51.01,-8.18) .. (-50.49,-6.83)
 .. controls (-49.98,-5.48) and (-50.07,-5.71) .. (-50.13,-4.40)
 .. controls (-50.20,-3.10) and (-50.85,-1.54) .. (-51.21,-0.89)
 .. controls (-51.57,-0.24) and (-52.02,0.84) .. (-53.51,0.89)
 .. controls (-54.99,0.93) and (-56.66,0.23) .. (-57.56,0.23)
 .. controls (-58.46,0.23) and (-59.52,1.18) .. (-59.67,1.88)
 .. controls (-59.83,2.57) and (-60.06,3.74) .. (-60.51,4.24)
 .. controls (-60.96,4.73) and (-61.41,4.80) .. (-61.48,5.39)
 .. controls (-61.54,5.97) and (-61.72,7.32) .. (-60.91,7.88)
 .. controls (-60.10,8.45) and (-58.57,8.31) .. (-58.08,9.26)
 .. controls (-57.58,10.20) and (-56.93,11.69) .. (-57.22,13.42)
 .. controls (-57.52,15.15) and (-56.32,18.14) .. (-55.67,18.59)
),
1,reverse ((-63.25,-10.27)
 .. controls (-63.16,-10.45) and (-62.10,-11.82) .. (-61.92,-12.21)
 .. controls (-60.35,-15.79) and (-54.88,-13.83) .. (-54.25,-11.40)
 .. controls (-53.62,-8.97) and (-52.11,-8.41) .. (-52.11,-8.41)
));
draw_downscrap;
endfig;
background:=(0.25000,0.31000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.31000, 1.00000);
current_scrap := "D35_20160913-_SP5@D35__20160913_.D35projet";
ATTR__scrap := "D35_20160913-_SP5";
beginfig(191);
ATTR__survey := "D35__20160913_.D35projet";
current_src := "D35_20160913-.th2 [780]";
string area_border[];
area_border[1] := "l107-1218-941";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-12.39,21.39)
 .. controls (-12.39,21.39) and (-20.85,25.13) .. (-21.98,24.72)
 .. controls (-23.10,24.32) and (-17.03,7.95) .. (-17.03,7.95)
 -- (-6.70,6.57)
 -- cycle
)));
ATTR__height := -1;
drawoptions();
l_rockborder(((-6.21,-18.55)
 -- (-6.07,-19.78)
 -- (-5.35,-19.83)
 -- (-5.31,-18.73)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-6.59,-13.94)
 -- (-6.89,-15.69)
 .. controls (-6.89,-15.69) and (-6.53,-15.96) .. (-6.26,-15.96)
 .. controls (-5.99,-15.96) and (-5.77,-15.30) .. (-5.77,-15.30)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-6.34,-17.23)
 -- (-5.85,-17.89)
 -- (-5.31,-17.28)
 -- (-5.32,-16.14)
 .. controls (-5.32,-16.14) and (-5.68,-15.74) .. (-5.90,-16.05)
 .. controls (-6.12,-16.35) and (-6.34,-17.23) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-5.63,-21.11)
 -- (-5.95,-22.03)
 -- (-5.36,-22.57)
 -- (-4.82,-22.18)
 -- (-4.86,-21.34)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-12.32,6.54)
 -- (-12.41,5.37)
 -- (-12.19,3.70)
 -- (-11.25,3.78)
 -- (-11.02,4.78)
 -- (-11.69,6.41)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-9.28,4.09)
 -- (-10.22,3.41)
 -- (-10.53,2.60)
 -- (-9.10,2.23)
 -- (-8.96,3.13)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-10.40,1.43)
 .. controls (-10.54,1.30) and (-10.71,0.18) .. (-10.58,0.04)
 .. controls (-10.44,-0.10) and (-8.79,-0.38) .. (-8.79,-0.38)
 -- (-9.06,0.65)
 .. controls (-9.06,0.65) and (-10.27,1.56) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-12.05,5.64)
 -- (-11.74,4.83)
 -- (-11.92,4.38)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-9.55,2.78)
 -- (-9.50,3.41)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-10.00,0.48)
 -- (-9.37,0.30)
));
endfig;
beginfig(192);
draw_upscrap(1)(1,((-21.48,27.69)
 .. controls (-21.48,27.69) and (-20.36,23.55) .. (-19.45,22.07)
 .. controls (-18.55,20.59) and (-16.06,15.29) .. (-14.84,11.67)
 .. controls (-13.62,8.03) and (-12.77,1.14) .. (-12.50,-0.34)
 .. controls (-12.22,-1.81) and (-10.40,-5.06) .. (-10.39,-6.12)
 .. controls (-10.37,-7.17) and (-9.93,-6.56) .. (-10.60,-9.13)
 .. controls (-11.27,-11.70) and (-13.32,-17.55) .. (-13.89,-18.94)
 .. controls (-14.46,-20.33) and (-16.34,-27.66) .. (-16.34,-27.66)
),
1,((-11.19,-26.44)
 .. controls (-11.14,-25.48) and (-6.67,-22.68) .. (-5.09,-23.94)
),
1,reverse ((-4.05,-23.16)
 .. controls (-4.05,-23.16) and (-2.97,-25.77) .. (-5.09,-23.94)
),
1,((-4.05,-23.16)
 .. controls (-4.95,-19.93) and (-5.67,-12.37) .. (-5.39,-10.02)
 .. controls (-5.11,-7.67) and (-5.73,-0.97) .. (-5.87,-0.25)
 .. controls (-6.00,0.47) and (-8.05,6.31) .. (-9.71,8.83)
 .. controls (-11.37,11.36) and (-13.46,16.46) .. (-14.10,18.03)
 .. controls (-14.73,19.60) and (-15.18,21.53) .. (-14.69,22.96)
));
draw_downscrap;
endfig;
beginfig(193);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-21.48,27.69)
 .. controls (-21.48,27.69) and (-20.36,23.55) .. (-19.45,22.07)
 .. controls (-18.55,20.59) and (-16.06,15.29) .. (-14.84,11.67)
 .. controls (-13.62,8.03) and (-12.77,1.14) .. (-12.50,-0.34)
 .. controls (-12.22,-1.81) and (-10.40,-5.06) .. (-10.39,-6.12)
 .. controls (-10.37,-7.17) and (-9.93,-6.56) .. (-10.60,-9.13)
 .. controls (-11.27,-11.70) and (-13.32,-17.55) .. (-13.89,-18.94)
 .. controls (-14.46,-20.33) and (-16.34,-27.66) .. (-16.34,-27.66)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.05,-23.16)
 .. controls (-4.95,-19.93) and (-5.67,-12.37) .. (-5.39,-10.02)
 .. controls (-5.11,-7.67) and (-5.73,-0.97) .. (-5.87,-0.25)
 .. controls (-6.00,0.47) and (-8.05,6.31) .. (-9.71,8.83)
 .. controls (-11.37,11.36) and (-13.46,16.46) .. (-14.10,18.03)
 .. controls (-14.73,19.60) and (-15.18,21.53) .. (-14.69,22.96)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.05,-23.16)
 .. controls (-4.05,-23.16) and (-2.97,-25.77) .. (-5.09,-23.94)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-11.30,16.55)
 -- (20.53,16.61)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-8.55,-3.05)
 .. controls (-8.55,-3.05) and (-6.90,-5.66) .. (-7.63,-7.75)
 .. controls (-8.35,-9.84) and (-9.88,-11.75) .. (-10.27,-13.19)
 .. controls (-10.65,-14.63) and (-11.49,-18.56) .. (-11.53,-18.96)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.19,-26.44)
 .. controls (-11.14,-25.48) and (-6.67,-22.68) .. (-5.09,-23.94)
));
endfig;
beginfig(194);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char97 \char115 \char115 \char97 \char103 \char101 \ \char98 \char97 \char115 \ \char97 \char113 \char117 \char97 \char116 \char105 \char113 \char117 \char101 \ \char115 \char111 \char117 \char115 \ \char98 \char108 \char111 \char99 \char115 \ \char115 \char117 \char115 \char112 \char101 \char110 \char100 \char117 \char115 \mainfont{} etex,(23.10,16.66),0.0,0);
endfig;
background:=(0.25000,0.32500,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.32500, 1.00000);
current_scrap := "D35_20160913-_SP4@D35__20160913_.D35projet";
ATTR__scrap := "D35_20160913-_SP4";
beginfig(195);
draw_upscrap(1)(1,((-1.76,-28.51)
 .. controls (-1.62,-27.43) and (-0.09,-24.55) .. (-0.05,-23.15)
 .. controls (-0.00,-21.76) and (1.08,-12.76) .. (1.53,-10.15)
 .. controls (1.98,-7.54) and (1.98,-6.23) .. (3.19,-3.13)
 .. controls (4.41,-0.02) and (2.43,2.95) .. (2.43,5.06)
 .. controls (2.43,7.18) and (3.83,9.43) .. (4.19,10.10)
 .. controls (4.55,10.78) and (4.73,13.88) .. (5.45,14.83)
 .. controls (6.17,15.77) and (7.47,16.45) .. (7.74,17.30)
 .. controls (8.01,18.16) and (7.29,20.50) .. (7.43,22.79)
 .. controls (7.56,25.09) and (8.69,26.93) .. (8.69,26.93)
),
1,((5.31,28.51)
 .. controls (5.31,28.51) and (5.04,25.31) .. (4.73,24.19)
 .. controls (4.41,23.06) and (4.01,20.86) .. (3.92,20.00)
 .. controls (3.83,19.15) and (2.34,11.27) .. (0.68,10.55)
 .. controls (-0.99,9.83) and (-5.94,11.27) .. (-6.03,9.07)
 .. controls (-6.12,6.86) and (-3.38,0.16) .. (-3.42,-2.63)
 .. controls (-3.47,-5.42) and (-1.26,-10.42) .. (-2.84,-13.03)
 .. controls (-4.41,-15.64) and (-7.43,-16.85) .. (-7.74,-18.52)
 .. controls (-8.06,-20.18) and (-8.69,-22.93) .. (-8.55,-23.78)
));
draw_downscrap;
endfig;
beginfig(196);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1.76,-28.51)
 .. controls (-1.62,-27.43) and (-0.09,-24.55) .. (-0.05,-23.15)
 .. controls (-0.00,-21.76) and (1.08,-12.76) .. (1.53,-10.15)
 .. controls (1.98,-7.54) and (1.98,-6.23) .. (3.19,-3.13)
 .. controls (4.41,-0.02) and (2.43,2.95) .. (2.43,5.06)
 .. controls (2.43,7.18) and (3.83,9.43) .. (4.19,10.10)
 .. controls (4.55,10.78) and (4.73,13.88) .. (5.45,14.83)
 .. controls (6.17,15.77) and (7.47,16.45) .. (7.74,17.30)
 .. controls (8.01,18.16) and (7.29,20.50) .. (7.43,22.79)
 .. controls (7.56,25.09) and (8.69,26.93) .. (8.69,26.93)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((3.56,12.94)
 .. controls (3.56,12.94) and (1.40,8.84) .. (0.05,8.17)
 .. controls (-1.30,7.49) and (-2.61,4.61) .. (-2.39,0.34)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((5.31,28.51)
 .. controls (5.31,28.51) and (5.04,25.31) .. (4.73,24.19)
 .. controls (4.41,23.06) and (4.01,20.86) .. (3.92,20.00)
 .. controls (3.83,19.15) and (2.34,11.27) .. (0.68,10.55)
 .. controls (-0.99,9.83) and (-5.94,11.27) .. (-6.03,9.07)
 .. controls (-6.12,6.86) and (-3.38,0.16) .. (-3.42,-2.63)
 .. controls (-3.47,-5.42) and (-1.26,-10.42) .. (-2.84,-13.03)
 .. controls (-4.41,-15.64) and (-7.43,-16.85) .. (-7.74,-18.52)
 .. controls (-8.06,-20.18) and (-8.69,-22.93) .. (-8.55,-23.78)
));
endfig;
background:=(0.25000,0.35500,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.35500, 1.00000);
current_scrap := "D35_20160913-_SP3@D35__20160913_.D35projet";
ATTR__scrap := "D35_20160913-_SP3";
beginfig(197);
draw_upscrap(1)(1,((-27.94,18.18)
 .. controls (-27.94,18.18) and (-26.95,16.06) .. (-26.91,14.67)
 .. controls (-26.86,13.27) and (-26.14,11.74) .. (-23.62,10.84)
 .. controls (-21.10,9.95) and (-18.49,9.99) .. (-17.19,10.04)
 .. controls (-15.88,10.08) and (-15.21,9.90) .. (-14.94,8.78)
 .. controls (-14.67,7.65) and (-13.18,5.58) .. (-13.23,4.37)
 .. controls (-13.27,3.15) and (-13.05,1.53) .. (-13.23,0.00)
 .. controls (-13.41,-1.53) and (-13.05,-3.64) .. (-14.04,-4.59)
 .. controls (-15.03,-5.53) and (-15.52,-7.29) .. (-15.43,-8.50)
 .. controls (-15.34,-9.72) and (-14.53,-12.51) .. (-15.03,-13.54)
 .. controls (-15.52,-14.58) and (-17.55,-15.66) .. (-17.77,-19.30)
),
1,((-14.40,-20.88)
 .. controls (-14.40,-20.88) and (-12.64,-18.09) .. (-11.61,-15.43)
 .. controls (-10.57,-12.78) and (-10.98,-9.94) .. (-9.99,-8.19)
 .. controls (-9.00,-6.43) and (-6.93,-3.32) .. (-7.92,1.22)
 .. controls (-8.14,2.25) and (-9.40,0.00) .. (-9.67,3.78)
),
1,((-9.67,3.78)
 .. controls (-9.67,3.78) and (-9.99,7.97) .. (-9.67,9.59)
 .. controls (-9.36,11.21) and (-7.78,16.58) .. (-13.05,16.96)
 .. controls (-15.52,17.14) and (-15.61,15.30) .. (-17.59,16.29)
 .. controls (-19.57,17.28) and (-21.33,19.08) .. (-21.33,19.08)
));
draw_downscrap;
endfig;
beginfig(198);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-27.94,18.18)
 .. controls (-27.94,18.18) and (-26.95,16.06) .. (-26.91,14.67)
 .. controls (-26.86,13.27) and (-26.14,11.74) .. (-23.62,10.84)
 .. controls (-21.10,9.95) and (-18.49,9.99) .. (-17.19,10.04)
 .. controls (-15.88,10.08) and (-15.21,9.90) .. (-14.94,8.78)
 .. controls (-14.67,7.65) and (-13.18,5.58) .. (-13.23,4.37)
 .. controls (-13.27,3.15) and (-13.05,1.53) .. (-13.23,0.00)
 .. controls (-13.41,-1.53) and (-13.05,-3.64) .. (-14.04,-4.59)
 .. controls (-15.03,-5.53) and (-15.52,-7.29) .. (-15.43,-8.50)
 .. controls (-15.34,-9.72) and (-14.53,-12.51) .. (-15.03,-13.54)
 .. controls (-15.52,-14.58) and (-17.55,-15.66) .. (-17.77,-19.30)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-14.40,-20.88)
 .. controls (-14.40,-20.88) and (-12.64,-18.09) .. (-11.61,-15.43)
 .. controls (-10.57,-12.78) and (-10.98,-9.94) .. (-9.99,-8.19)
 .. controls (-9.00,-6.43) and (-6.93,-3.32) .. (-7.92,1.22)
 .. controls (-8.14,2.25) and (-9.40,0.00) .. (-9.67,3.78)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-12.87,8.01)
 .. controls (-12.87,8.01) and (-11.43,0.99) .. (-12.24,-3.15)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.67,3.78)
 .. controls (-9.67,3.78) and (-9.99,7.97) .. (-9.67,9.59)
 .. controls (-9.36,11.21) and (-7.78,16.58) .. (-13.05,16.96)
 .. controls (-15.52,17.14) and (-15.61,15.30) .. (-17.59,16.29)
 .. controls (-19.57,17.28) and (-21.33,19.08) .. (-21.33,19.08)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-7.11,14.04)
 -- (24.75,14.04)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-27.49,20.88)
 .. controls (-27.49,20.88) and (-26.37,16.87) .. (-25.29,15.25)
 .. controls (-24.21,13.63) and (-20.02,12.15) .. (-18.40,12.33)
));
endfig;
beginfig(199);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char82 \char50 \mainfont{} etex,(27.94,14.04),0.0,0);
endfig;
background:=(0.25000,0.39250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.39250, 1.00000);
current_scrap := "D35_20160913-_SP2@D35__20160913_.D35projet";
ATTR__scrap := "D35_20160913-_SP2";
beginfig(200);
ATTR__height := -1;
drawoptions();
l_rockborder(((-51.57,-67.46)
 -- (-51.77,-68.88)
 -- (-50.37,-71.23)
 -- (-48.27,-70.26)
 -- (-47.83,-68.81)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-48.87,-67.37)
 -- (-47.43,-68.31)
 -- (-47.16,-69.22)
 -- (-47.38,-70.12)
 -- (-45.85,-69.80)
 -- (-45.50,-68.71)
 -- (-45.96,-67.13)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-47.51,-70.93)
 -- (-48.76,-72.16)
 .. controls (-48.76,-72.16) and (-49.26,-73.33) .. (-49.12,-73.51)
 .. controls (-48.99,-73.69) and (-48.08,-74.68) .. (-48.08,-74.68)
 -- (-46.34,-72.83)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-50.42,-68.79)
 -- (-49.74,-69.51)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-46.72,-67.85)
 -- (-46.53,-68.44)
 -- (-46.53,-69.48)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-47.37,-72.38)
 -- (-48.22,-73.10)
));
ATTR__height := -1;
drawoptions();
l_pit(((-44.88,-66.81)
 .. controls (-44.38,-65.46) and (-46.69,-63.56) .. (-47.40,-62.72)
 .. controls (-48.11,-61.87) and (-49.95,-62.69) .. (-50.19,-63.53)
 .. controls (-50.43,-64.37) and (-51.25,-65.53) .. (-51.25,-65.53)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-57.32,-42.83)
 -- (-58.04,-43.01)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-57.32,-42.83)
 -- (-57.00,-41.97)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-57.32,-42.83)
 -- (-55.78,-45.47)
 -- (-55.59,-46.25)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-55.78,-45.47)
 -- (-55.06,-45.42)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-57.97,-41.61)
 -- (-58.72,-43.22)
 -- (-57.37,-45.45)
 -- (-55.02,-47.55)
 -- (-54.44,-45.78)
 -- (-56.19,-41.66)
 -- cycle
));
endfig;
beginfig(201);
draw_upscrap(1)(1,((-42.13,-77.00)
 .. controls (-42.13,-77.00) and (-44.98,-74.86) .. (-45.39,-73.60)
 .. controls (-45.80,-72.33) and (-46.07,-71.42) .. (-45.31,-70.02)
 .. controls (-44.56,-68.62) and (-43.58,-67.03) .. (-45.01,-64.39)
 .. controls (-46.42,-61.77) and (-48.55,-61.37) .. (-48.60,-59.09)
 .. controls (-48.65,-56.77) and (-54.19,-44.77) .. (-55.22,-42.84)
 .. controls (-56.23,-40.94) and (-56.49,-37.71) .. (-62.01,-36.93)
 .. controls (-67.79,-36.12) and (-67.57,-37.49) .. (-69.42,-34.12)
 .. controls (-71.35,-30.61) and (-75.91,-24.01) .. (-76.03,-21.56)
 .. controls (-76.15,-19.13) and (-76.06,-19.66) .. (-76.06,-19.66)
),
1,((-84.02,-23.53)
 .. controls (-84.02,-23.53) and (-80.84,-27.19) .. (-80.14,-28.89)
 .. controls (-79.42,-30.64) and (-76.97,-32.21) .. (-75.58,-33.75)
 .. controls (-74.17,-35.30) and (-74.19,-35.29) .. (-73.88,-36.72)
 .. controls (-73.58,-38.13) and (-73.14,-38.58) .. (-73.01,-39.81)
),
1,((-61.09,-54.10)
 .. controls (-59.10,-54.37) and (-55.65,-57.54) .. (-52.57,-60.80)
 .. controls (-48.67,-64.91) and (-52.87,-65.03) .. (-52.74,-66.52)
 .. controls (-52.60,-68.00) and (-49.33,-76.95) .. (-48.74,-77.89)
));
draw_downscrap;
endfig;
beginfig(202);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-61.09,-54.10)
 .. controls (-59.10,-54.37) and (-55.65,-57.54) .. (-52.57,-60.80)
 .. controls (-48.67,-64.91) and (-52.87,-65.03) .. (-52.74,-66.52)
 .. controls (-52.60,-68.00) and (-49.33,-76.95) .. (-48.74,-77.89)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-84.02,-23.53)
 .. controls (-84.02,-23.53) and (-80.84,-27.19) .. (-80.14,-28.89)
 .. controls (-79.42,-30.64) and (-76.97,-32.21) .. (-75.58,-33.75)
 .. controls (-74.17,-35.30) and (-74.19,-35.29) .. (-73.88,-36.72)
 .. controls (-73.58,-38.13) and (-73.14,-38.58) .. (-73.01,-39.81)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-42.13,-77.00)
 .. controls (-42.13,-77.00) and (-44.98,-74.86) .. (-45.39,-73.60)
 .. controls (-45.80,-72.33) and (-46.07,-71.42) .. (-45.31,-70.02)
 .. controls (-44.56,-68.62) and (-43.58,-67.03) .. (-45.01,-64.39)
 .. controls (-46.42,-61.77) and (-48.55,-61.37) .. (-48.60,-59.09)
 .. controls (-48.65,-56.77) and (-54.19,-44.77) .. (-55.22,-42.84)
 .. controls (-56.23,-40.94) and (-56.49,-37.71) .. (-62.01,-36.93)
 .. controls (-67.79,-36.12) and (-67.57,-37.49) .. (-69.42,-34.12)
 .. controls (-71.35,-30.61) and (-75.91,-24.01) .. (-76.03,-21.56)
 .. controls (-76.15,-19.13) and (-76.06,-19.66) .. (-76.06,-19.66)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-64.36,-45.24)
 .. controls (-64.36,-45.24) and (-58.00,-48.73) .. (-56.75,-50.84)
 .. controls (-55.40,-53.10) and (-54.35,-54.73) .. (-54.09,-55.40)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-42.31,-67.48)
 -- (-17.55,-67.44)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-47.56,-58.91)
 -- (-36.46,-48.15)
 -- (-17.54,-48.20)
));
endfig;
beginfig(203);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char53 \ \char108 \char112 \char115 \ \char49 \char51 \char47 \char48 \char57 \char47 \char50 \char48 \char49 \char54 \ \char49 \char57 \char58 \char48 \char48 \mainfont{} etex,(-15.60,-48.20),0.0,0);
ATTR__height := -1;
drawoptions();
l_label(btex \thhugesize \thfb\char82 {}\char105 {}\char118 {}\char105 {}\accent18 \char101 {}\char114 {}\char101 {}\ \char45 {}\ \char49 {}\char48 {}\char48 {}\char48 {}\mainfont{} etex,((35.87,115.55)
 .. controls (35.87,115.55) and (53.21,66.96) .. (53.48,46.08)
 .. controls (54.17,-7.55) and (65.32,-21.59) .. (74.67,-47.15)
 .. controls (84.02,-72.71) and (81.50,-109.43) .. (81.14,-115.55)
));
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char67 \char51 \mainfont{} etex,(-15.02,-67.39),0.0,0);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char49 \char48 \char49 \char57 \mainfont{} etex,(-50.30,-54.01),0.0,1);
endfig;
background:=(0.25000,0.43000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.43000, 1.00000);
current_scrap := "D35_20160913-_SP1@D35__20160913_.D35projet";
ATTR__scrap := "D35_20160913-_SP1";
beginfig(204);
current_src := "D35_20160913-.th2 [16]";
string area_border[];
area_border[1] := "l71-763-3311";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-9.84,11.50)
 .. controls (-9.84,11.50) and (-17.47,17.00) .. (-19.55,12.83)
 .. controls (-21.63,8.67) and (-23.03,-6.45) .. (-19.22,-6.88)
 .. controls (-15.41,-7.32) and (-6.00,-7.74) .. (-6.00,-7.74)
 -- cycle
)));
ATTR__height := -1;
drawoptions();
l_rockborder(((-15.11,-11.27)
 -- (-15.21,-12.17)
 -- (-14.89,-12.84)
 -- (-14.26,-11.90)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-12.72,-8.35)
 -- (-13.22,-9.21)
 -- (-12.77,-9.88)
 -- (-12.01,-9.39)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-16.33,-18.75)
 -- (-16.55,-19.65)
 -- (-15.96,-20.23)
 -- (-15.11,-19.19)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-22.73,43.59)
 -- (-22.47,42.79)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-24.93,48.88)
 -- (-24.71,48.34)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-10.54,27.91)
 -- (-10.61,27.02)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-13.75,30.73)
 -- (-13.90,29.98)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-7.70,27.54)
 -- (-7.58,26.92)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-9.57,22.76)
 -- (-8.97,23.07)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-11.91,21.31)
 -- (-11.37,20.86)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-15.05,24.96)
 -- (-14.76,25.54)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-12.17,17.60)
 -- (-11.80,18.09)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-11.48,24.77)
 -- (-10.94,24.73)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-25.22,52.01)
 -- (-25.17,51.23)
 -- (-24.68,50.90)
 -- (-24.44,51.56)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-25.38,49.08)
 -- (-25.22,48.24)
 -- (-24.58,47.80)
 -- (-24.34,48.54)
 -- (-24.70,49.53)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-7.33,-40.70)
 -- (-8.05,-41.87)
 -- (-7.42,-42.55)
 .. controls (-7.42,-42.55) and (-6.07,-42.50) .. (-6.07,-42.23)
 .. controls (-6.07,-41.96) and (-7.33,-40.70) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-4.85,-42.68)
 -- (-5.30,-43.27)
 -- (-5.35,-43.94)
 -- (-4.41,-44.12)
 -- (-3.55,-43.81)
 -- (-3.86,-42.91)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-14.12,31.57)
 -- (-14.62,30.07)
 -- (-13.98,28.97)
 -- (-12.92,29.89)
 -- (-13.09,31.52)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-11.20,28.48)
 -- (-11.79,26.81)
 -- (-11.28,25.66)
 -- (-9.18,26.22)
 -- (-9.34,27.24)
 -- (-9.88,28.97)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-15.32,26.59)
 -- (-15.85,23.82)
 -- (-14.06,24.96)
 -- (-13.67,26.02)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-13.37,28.49)
 -- (-13.58,27.39)
 -- (-12.36,27.65)
 -- (-11.86,29.19)
 -- (-12.58,29.15)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-10.01,23.48)
 -- (-10.66,22.42)
 -- (-9.76,21.87)
 -- (-8.29,22.75)
 -- (-8.04,24.44)
 -- (-9.00,23.91)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-8.96,20.40)
 -- (-9.06,19.32)
 -- (-8.47,19.23)
 -- (-7.64,20.07)
 -- (-7.72,21.23)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-23.04,44.98)
 .. controls (-23.04,44.98) and (-24.23,44.43) .. (-23.40,42.83)
 .. controls (-22.62,41.31) and (-22.08,41.05) .. (-22.08,41.05)
 .. controls (-22.08,41.05) and (-21.47,42.61) .. (-21.62,43.29)
 .. controls (-22.06,45.22) and (-23.04,44.98) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-12.66,18.14)
 -- (-12.58,16.89)
 -- (-11.39,17.55)
 -- (-11.12,18.53)
 -- (-12.02,18.90)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-9.62,16.82)
 -- (-9.48,18.25)
 -- (-8.57,17.66)
 -- (-8.66,17.21)
 -- (-9.03,16.54)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-10.92,20.01)
 -- (-10.69,20.41)
 -- (-11.00,21.30)
 -- (-12.26,21.85)
 -- (-12.55,21.27)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-11.78,23.71)
 -- (-11.98,22.51)
 -- (-10.65,22.95)
 -- (-10.31,24.19)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-11.74,25.13)
 -- (-12.13,24.25)
 -- (-10.13,24.45)
 -- (-9.92,25.52)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-8.06,25.55)
 -- (-8.66,24.84)
 -- (-7.35,24.57)
 -- (-6.44,24.56)
 -- (-6.12,25.09)
 -- (-6.65,25.68)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-7.96,28.12)
 -- (-8.53,27.06)
 -- (-7.27,26.34)
 -- (-6.71,27.36)
 -- (-7.23,28.21)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-7.15,19.49)
 -- (-7.29,18.77)
 -- (-6.19,18.90)
 -- (-6.14,19.83)
 -- cycle
));
endfig;
beginfig(205);
draw_upscrap(1)(1,((-27.20,51.27)
 .. controls (-26.18,49.22) and (-25.31,47.47) .. (-25.06,45.50)
 .. controls (-24.82,43.53) and (-24.47,37.03) .. (-24.14,35.70)
 .. controls (-23.82,34.38) and (-21.55,24.80) .. (-21.41,22.77)
 .. controls (-21.28,20.73) and (-19.79,17.25) .. (-19.25,16.90)
 .. controls (-18.72,16.54) and (-17.80,12.66) .. (-17.15,10.40)
 .. controls (-16.51,8.13) and (-14.96,0.74) .. (-14.97,-0.33)
 .. controls (-14.97,-1.41) and (-14.63,-4.81) .. (-14.73,-5.89)
 .. controls (-14.83,-6.97) and (-15.10,-8.04) .. (-15.33,-8.54)
 .. controls (-15.56,-9.03) and (-15.92,-10.64) .. (-16.33,-11.23)
 .. controls (-16.73,-11.81) and (-17.09,-12.58) .. (-17.09,-13.39)
 .. controls (-17.09,-14.20) and (-17.41,-15.28) .. (-17.54,-16.40)
 .. controls (-17.67,-17.53) and (-17.98,-20.14) .. (-18.48,-21.54)
 .. controls (-18.97,-22.94) and (-19.56,-25.23) .. (-19.38,-26.80)
 .. controls (-19.20,-28.38) and (-18.85,-30.76) .. (-18.67,-31.84)
 .. controls (-18.49,-32.91) and (-18.23,-37.68) .. (-18.04,-38.22)
 .. controls (-17.86,-38.76) and (-15.25,-45.47) .. (-14.57,-46.28)
 .. controls (-13.90,-47.09) and (-11.65,-51.63) .. (-9.50,-53.43)
),
1,((-1.53,-49.56)
 .. controls (-1.53,-49.11) and (-1.62,-46.14) .. (-1.17,-44.21)
 .. controls (-0.71,-42.28) and (-4.45,-39.67) .. (-6.74,-38.37)
 .. controls (-9.04,-37.06) and (-10.93,-36.74) .. (-11.20,-35.48)
 .. controls (-11.47,-34.22) and (-11.29,-33.41) .. (-11.02,-32.52)
 .. controls (-10.74,-31.62) and (-10.34,-30.13) .. (-10.70,-29.59)
 .. controls (-11.06,-29.05) and (-13.53,-22.57) .. (-13.53,-20.50)
 .. controls (-13.54,-18.43) and (-12.15,-13.16) .. (-11.70,-12.17)
 .. controls (-11.25,-11.18) and (-9.83,-6.52) .. (-10.49,-3.74)
 .. controls (-11.15,-0.96) and (-11.81,6.01) .. (-12.31,7.41)
 .. controls (-12.81,8.81) and (-13.14,9.94) .. (-13.19,11.16)
 .. controls (-13.24,12.38) and (-12.12,13.50) .. (-10.94,14.76)
 .. controls (-9.76,16.01) and (-5.32,15.88) .. (-5.59,20.41)
 .. controls (-5.86,24.91) and (-6.15,28.29) .. (-7.50,28.69)
 .. controls (-8.84,29.10) and (-12.85,32.14) .. (-14.04,34.39)
 .. controls (-15.24,36.64) and (-18.84,40.26) .. (-19.67,41.78)
 .. controls (-20.51,43.29) and (-21.05,47.22) .. (-22.22,48.98)
 .. controls (-23.43,50.81) and (-23.04,52.30) .. (-23.62,53.36)
));
draw_downscrap;
endfig;
beginfig(206);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-27.20,51.27)
 .. controls (-26.18,49.22) and (-25.31,47.47) .. (-25.06,45.50)
 .. controls (-24.82,43.53) and (-24.47,37.03) .. (-24.14,35.70)
 .. controls (-23.82,34.38) and (-21.55,24.80) .. (-21.41,22.77)
 .. controls (-21.28,20.73) and (-19.79,17.25) .. (-19.25,16.90)
 .. controls (-18.72,16.54) and (-17.80,12.66) .. (-17.15,10.40)
 .. controls (-16.51,8.13) and (-14.96,0.74) .. (-14.97,-0.33)
 .. controls (-14.97,-1.41) and (-14.63,-4.81) .. (-14.73,-5.89)
 .. controls (-14.83,-6.97) and (-15.10,-8.04) .. (-15.33,-8.54)
 .. controls (-15.56,-9.03) and (-15.92,-10.64) .. (-16.33,-11.23)
 .. controls (-16.73,-11.81) and (-17.09,-12.58) .. (-17.09,-13.39)
 .. controls (-17.09,-14.20) and (-17.41,-15.28) .. (-17.54,-16.40)
 .. controls (-17.67,-17.53) and (-17.98,-20.14) .. (-18.48,-21.54)
 .. controls (-18.97,-22.94) and (-19.56,-25.23) .. (-19.38,-26.80)
 .. controls (-19.20,-28.38) and (-18.85,-30.76) .. (-18.67,-31.84)
 .. controls (-18.49,-32.91) and (-18.23,-37.68) .. (-18.04,-38.22)
 .. controls (-17.86,-38.76) and (-15.25,-45.47) .. (-14.57,-46.28)
 .. controls (-13.90,-47.09) and (-11.65,-51.63) .. (-9.50,-53.43)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1.53,-49.56)
 .. controls (-1.53,-49.11) and (-1.62,-46.14) .. (-1.17,-44.21)
 .. controls (-0.71,-42.28) and (-4.45,-39.67) .. (-6.74,-38.37)
 .. controls (-9.04,-37.06) and (-10.93,-36.74) .. (-11.20,-35.48)
 .. controls (-11.47,-34.22) and (-11.29,-33.41) .. (-11.02,-32.52)
 .. controls (-10.74,-31.62) and (-10.34,-30.13) .. (-10.70,-29.59)
 .. controls (-11.06,-29.05) and (-13.53,-22.57) .. (-13.53,-20.50)
 .. controls (-13.54,-18.43) and (-12.15,-13.16) .. (-11.70,-12.17)
 .. controls (-11.25,-11.18) and (-9.83,-6.52) .. (-10.49,-3.74)
 .. controls (-11.15,-0.96) and (-11.81,6.01) .. (-12.31,7.41)
 .. controls (-12.81,8.81) and (-13.14,9.94) .. (-13.19,11.16)
 .. controls (-13.24,12.38) and (-12.12,13.50) .. (-10.94,14.76)
 .. controls (-9.76,16.01) and (-5.32,15.88) .. (-5.59,20.41)
 .. controls (-5.86,24.91) and (-6.15,28.29) .. (-7.50,28.69)
 .. controls (-8.84,29.10) and (-12.85,32.14) .. (-14.04,34.39)
 .. controls (-15.24,36.64) and (-18.84,40.26) .. (-19.67,41.78)
 .. controls (-20.51,43.29) and (-21.05,47.22) .. (-22.22,48.98)
 .. controls (-23.43,50.81) and (-23.04,52.30) .. (-23.62,53.36)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-15.29,-29.72)
 .. controls (-15.29,-29.72) and (-16.69,-34.94) .. (-14.22,-39.80)
 .. controls (-11.74,-44.66) and (-10.25,-42.91) .. (-9.04,-45.47)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-21.20,37.85)
 .. controls (-21.20,37.85) and (-19.63,34.14) .. (-19.24,32.42)
 .. controls (-18.85,30.71) and (-18.38,26.02) .. (-18.42,24.83)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-10.37,2.94)
 -- (0.36,13.34)
 -- (25.49,13.29)
));
endfig;
beginfig(207);
drawoptions();
p_label.rt(btex \thaltitude \thfb\char49 \char48 \char50 \char50 \mainfont{} etex,(-10.43,-30.09),0.0,1);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char66 \char97 \char115 \char115 \char105 \char110 \ \char40 \char112 \char97 \char115 \char115 \char97 \char103 \char101 \ \char101 \char110 \ \char111 \char112 \char112 \char111 \char115 \char105 \char116 \char105 \char111 \char110 \char41 \mainfont{} etex,(27.20,13.29),0.0,0);
endfig;
background:=(0.78250,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.78250, 0.25000, 1.00000);
current_scrap := "D35_20161012SP14@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP14";
background:=(0.68500,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.68500, 0.25000, 1.00000);
current_scrap := "D35_20161012SP13@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP13";
beginfig(208);
ATTR__survey := "D35_20161012.D35projet";
ATTR__height := -1;
drawoptions();
l_pit(((-6.92,6.91)
 .. controls (-6.57,2.99) and (-13.69,-1.81) .. (-11.00,-9.16)
 .. controls (-8.31,-16.52) and (-9.62,-14.41) .. (-8.98,-15.49)
 .. controls (-8.36,-16.56) and (-8.10,-21.11) .. (-7.52,-22.07)
 .. controls (-6.92,-23.08) and (0.16,-29.24) .. (1.07,-26.95)
 .. controls (2.18,-24.17) and (2.09,-9.02) .. (2.58,-7.56)
 .. controls (3.06,-6.11) and (0.47,1.31) .. (0.59,2.99)
 .. controls (0.71,4.62) and (1.31,8.23) .. (1.24,9.49)
 .. controls (1.17,10.74) and (-1.42,15.01) .. (-2.92,11.06)
 .. controls (-3.40,9.77) and (-7.41,12.48) .. cycle
));
endfig;
beginfig(209);
draw_upscrap(1)(1,((-73.88,9.58)
 .. controls (-73.88,9.58) and (-72.08,7.23) .. (-64.07,4.91)
 .. controls (-56.09,2.60) and (-52.62,2.19) .. (-51.53,1.83)
 .. controls (-50.45,1.46) and (-47.17,-2.12) .. (-45.82,-2.57)
 .. controls (-44.47,-3.02) and (-41.95,-5.46) .. (-41.23,-6.18)
 .. controls (-40.51,-6.89) and (-39.93,-8.41) .. (-39.12,-9.04)
 .. controls (-38.31,-9.68) and (-37.28,-10.35) .. (-35.38,-9.19)
 .. controls (-33.48,-8.03) and (-31.84,-5.05) .. (-30.40,-3.89)
 .. controls (-28.96,-2.73) and (-27.70,-0.28) .. (-25.73,-0.55)
 .. controls (-23.75,-0.82) and (-22.39,-0.92) .. (-21.58,-0.93)
 .. controls (-20.77,-0.93) and (-13.86,-0.46) .. (-13.41,-4.26)
 .. controls (-12.96,-8.00) and (-11.18,-10.19) .. (-10.91,-12.00)
 .. controls (-10.65,-13.78) and (-9.25,-20.27) .. (-9.17,-21.45)
),
1,((5.83,-22.41)
 .. controls (5.83,-22.41) and (8.43,-17.42) .. (8.18,-15.11)
 .. controls (7.94,-12.84) and (5.65,-9.07) .. (4.73,-6.45)
 .. controls (3.81,-3.84) and (4.27,-0.56) .. (3.97,0.51)
 .. controls (3.66,1.56) and (3.60,3.26) .. (3.23,4.20)
 .. controls (2.86,5.13) and (3.83,8.69) .. (3.53,10.02)
 .. controls (3.24,11.33) and (3.64,16.12) .. (3.99,17.31)
),
1,((-3.98,19.13)
 .. controls (-3.98,19.13) and (-2.46,17.06) .. (-2.75,14.06)
 .. controls (-3.00,11.50) and (-3.21,11.63) .. (-5.86,11.72)
 .. controls (-8.46,11.80) and (-7.77,3.27) .. (-9.15,3.59)
 .. controls (-10.52,3.90) and (-16.95,3.70) .. (-16.95,3.70)
 .. controls (-16.95,3.70) and (-24.78,5.06) .. (-25.35,3.69)
 .. controls (-26.07,1.96) and (-28.20,1.65) .. (-28.92,1.10)
 .. controls (-29.63,0.55) and (-33.56,-2.94) .. (-34.37,-2.75)
 .. controls (-35.18,-2.57) and (-41.68,-4.29) .. (-42.04,-2.67)
 .. controls (-42.40,-1.05) and (-40.55,0.10) .. (-41.27,0.56)
 .. controls (-41.99,1.01) and (-48.25,2.95) .. (-48.96,3.22)
 .. controls (-49.68,3.49) and (-54.37,7.14) .. (-55.45,7.50)
 .. controls (-56.53,7.85) and (-59.94,9.86) .. (-61.74,11.04)
 .. controls (-63.55,12.22) and (-66.66,14.67) .. (-66.66,14.67)
));
draw_downscrap;
endfig;
beginfig(210);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-73.88,9.58)
 .. controls (-73.88,9.58) and (-72.08,7.23) .. (-64.07,4.91)
 .. controls (-56.09,2.60) and (-52.62,2.19) .. (-51.53,1.83)
 .. controls (-50.45,1.46) and (-47.17,-2.12) .. (-45.82,-2.57)
 .. controls (-44.47,-3.02) and (-41.95,-5.46) .. (-41.23,-6.18)
 .. controls (-40.51,-6.89) and (-39.93,-8.41) .. (-39.12,-9.04)
 .. controls (-38.31,-9.68) and (-37.28,-10.35) .. (-35.38,-9.19)
 .. controls (-33.48,-8.03) and (-31.84,-5.05) .. (-30.40,-3.89)
 .. controls (-28.96,-2.73) and (-27.70,-0.28) .. (-25.73,-0.55)
 .. controls (-23.75,-0.82) and (-22.39,-0.92) .. (-21.58,-0.93)
 .. controls (-20.77,-0.93) and (-13.86,-0.46) .. (-13.41,-4.26)
 .. controls (-12.96,-8.00) and (-11.18,-10.19) .. (-10.91,-12.00)
 .. controls (-10.65,-13.78) and (-9.25,-20.27) .. (-9.17,-21.45)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((5.83,-22.41)
 .. controls (5.83,-22.41) and (8.43,-17.42) .. (8.18,-15.11)
 .. controls (7.94,-12.84) and (5.65,-9.07) .. (4.73,-6.45)
 .. controls (3.81,-3.84) and (4.27,-0.56) .. (3.97,0.51)
 .. controls (3.66,1.56) and (3.60,3.26) .. (3.23,4.20)
 .. controls (2.86,5.13) and (3.83,8.69) .. (3.53,10.02)
 .. controls (3.24,11.33) and (3.64,16.12) .. (3.99,17.31)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.98,19.13)
 .. controls (-3.98,19.13) and (-2.46,17.06) .. (-2.75,14.06)
 .. controls (-3.00,11.50) and (-3.21,11.63) .. (-5.86,11.72)
 .. controls (-8.46,11.80) and (-7.77,3.27) .. (-9.15,3.59)
 .. controls (-10.52,3.90) and (-16.95,3.70) .. (-16.95,3.70)
 .. controls (-16.95,3.70) and (-24.78,5.06) .. (-25.35,3.69)
 .. controls (-26.07,1.96) and (-28.20,1.65) .. (-28.92,1.10)
 .. controls (-29.63,0.55) and (-33.56,-2.94) .. (-34.37,-2.75)
 .. controls (-35.18,-2.57) and (-41.68,-4.29) .. (-42.04,-2.67)
 .. controls (-42.40,-1.05) and (-40.55,0.10) .. (-41.27,0.56)
 .. controls (-41.99,1.01) and (-48.25,2.95) .. (-48.96,3.22)
 .. controls (-49.68,3.49) and (-54.37,7.14) .. (-55.45,7.50)
 .. controls (-56.53,7.85) and (-59.94,9.86) .. (-61.74,11.04)
 .. controls (-63.55,12.22) and (-66.66,14.67) .. (-66.66,14.67)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((0.26,18.03)
 .. controls (0.26,18.03) and (0.38,16.19) .. (0.12,15.18)
 .. controls (-0.13,14.19) and (-0.09,15.09) .. (-0.45,13.48)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-59.04,6.50)
 .. controls (-59.04,6.50) and (-51.13,3.45) .. (-49.96,2.54)
 .. controls (-48.79,1.65) and (-41.28,-6.27) .. (-36.77,-6.45)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((6.13,0.92)
 -- (43.81,1.08)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((43.81,1.08)
 -- (68.40,25.72)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-28.78,-0.34)
 .. controls (-28.78,-0.34) and (-26.64,2.09) .. (-22.77,2.13)
 .. controls (-18.86,2.18) and (-14.90,0.01) .. (-14.27,-0.15)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((18.79,-12.47)
 -- (66.32,-13.02)
));
endfig;
beginfig(211);
drawoptions();
p_label.ulft(btex \thaltitude \thfb\char57 \char51 \char53 \mainfont{} etex,(-25.26,4.18),0.0,1);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char67 \char111 \char110 \char102 \char108 \char117 \char101 \char110 \char99 \char101 \ \char100 \char101 \char115 \ \char100 \char101 \char117 \char120 \ \char114 \char105 \char118 \char105 \accent18 \char101 \char114 \char101 \char115 \mainfont{} etex,(71.90,29.24),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char51 \char49 \mainfont{} etex,(73.88,-13.21),0.0,0);
endfig;
background:=(0.66250,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.66250, 0.25000, 1.00000);
current_scrap := "D35_20161012SP12@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP12";
beginfig(212);
draw_upscrap(1)(1,((14.00,-8.80)
 .. controls (14.00,-8.80) and (7.11,-4.61) .. (4.77,-1.91)
 .. controls (2.43,0.79) and (0.18,1.78) .. (-0.36,3.31)
 .. controls (-0.90,4.84) and (-0.59,10.51) .. (-3.29,11.50)
 .. controls (-5.99,12.49) and (-10.31,14.11) .. (-10.31,14.11)
),
1,((-14.00,2.59)
 .. controls (-14.00,2.59) and (-7.38,-1.69) .. (-6.39,-2.41)
 .. controls (-5.40,-3.13) and (0.90,-7.45) .. (1.98,-8.35)
 .. controls (3.06,-9.25) and (5.72,-11.68) .. (6.80,-14.11)
));
draw_downscrap;
endfig;
beginfig(213);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-14.00,2.59)
 .. controls (-14.00,2.59) and (-7.38,-1.69) .. (-6.39,-2.41)
 .. controls (-5.40,-3.13) and (0.90,-7.45) .. (1.98,-8.35)
 .. controls (3.06,-9.25) and (5.72,-11.68) .. (6.80,-14.11)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((14.00,-8.80)
 .. controls (14.00,-8.80) and (7.11,-4.61) .. (4.77,-1.91)
 .. controls (2.43,0.79) and (0.18,1.78) .. (-0.36,3.31)
 .. controls (-0.90,4.84) and (-0.59,10.51) .. (-3.29,11.50)
 .. controls (-5.99,12.49) and (-10.31,14.11) .. (-10.31,14.11)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-9.90,5.92)
 .. controls (-9.90,5.92) and (-0.85,-0.38) .. (2.03,-1.73)
 .. controls (4.91,-3.08) and (6.98,-6.28) .. (6.98,-6.28)
));
endfig;
beginfig(214);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char57 \char51 \char57 \mainfont{} etex,(-8.37,13.61),0.0,1);
endfig;
background:=(0.64000,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.64000, 0.25000, 1.00000);
current_scrap := "D35_20161012SP11@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP11";
beginfig(215);
current_src := "D35_20161012.th2 [1617]";
string area_border[];
area_border[1] := "l295-4768-6863";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-3.51,-2.41)
 .. controls (-3.51,-2.41) and (-8.32,-8.97) .. (-6.07,-9.74)
 .. controls (-3.82,-10.50) and (-1.30,-12.08) .. (1.71,-12.08)
 .. controls (4.72,-12.08) and (8.95,-14.87) .. (10.17,-13.70)
 .. controls (11.38,-12.53) and (12.01,-11.27) .. (10.35,-9.33)
 .. controls (8.68,-7.40) and (3.69,-4.70) .. (2.43,-3.80)
 .. controls (1.17,-2.90) and (-3.51,-2.41) .. cycle
)));
current_src := "D35_20161012.th2 [1613]";
string area_border[];
area_border[1] := "l294-4726-6737";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-25.28,-33.95)
 -- (-26.27,-41.10)
 -- (-9.08,-45.28)
 .. controls (-9.08,-45.28) and (6.12,-35.34) .. (6.26,-35.11)
 .. controls (6.39,-34.89) and (9.36,-29.67) .. (8.37,-25.75)
 .. controls (7.38,-21.84) and (7.20,-19.77) .. (7.29,-18.78)
 .. controls (7.38,-17.79) and (11.43,-14.96) .. (6.88,-14.37)
 .. controls (2.34,-13.79) and (-3.06,-13.92) .. (-3.33,-12.89)
 .. controls (-3.60,-11.85) and (-13.81,-22.88) .. (-14.71,-24.45)
 .. controls (-15.61,-26.03) and (-23.26,-34.17) .. (-25.28,-33.95)
)));
ATTR__height := -1;
drawoptions();
l_rockborder(((4.95,-2.18)
 -- (5.04,-3.39)
 .. controls (5.04,-3.39) and (6.48,-3.57) .. (6.52,-3.35)
 .. controls (6.57,-3.12) and (6.79,-2.36) .. (6.79,-2.36)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((8.19,-2.31)
 -- (7.60,-3.08)
 .. controls (7.60,-3.08) and (7.47,-3.71) .. (7.65,-3.89)
 .. controls (7.83,-4.07) and (9.72,-3.62) .. (9.72,-3.62)
 .. controls (9.72,-3.62) and (9.58,-2.63) .. (9.36,-2.49)
 .. controls (9.13,-2.36) and (8.19,-2.31) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((10.48,-3.12)
 -- (10.26,-3.30)
 -- (10.57,-4.25)
 .. controls (10.57,-4.25) and (11.70,-3.93) .. (11.70,-3.71)
 .. controls (11.70,-3.48) and (11.38,-3.21) .. (11.38,-3.21)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((12.55,-3.89)
 -- (12.06,-4.56)
 .. controls (12.06,-4.56) and (11.70,-5.28) .. (12.15,-5.33)
 .. controls (12.60,-5.37) and (12.91,-5.46) .. (13.00,-5.06)
 .. controls (13.09,-4.65) and (13.27,-4.07) .. (13.27,-4.07)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((14.08,-5.37)
 .. controls (14.08,-5.37) and (13.41,-6.18) .. (13.72,-6.32)
 .. controls (14.04,-6.45) and (14.62,-6.81) .. (14.80,-6.59)
 .. controls (14.98,-6.36) and (15.07,-6.18) .. (15.03,-5.96)
 .. controls (14.98,-5.73) and (14.08,-5.37) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-2.47,-11.94)
 .. controls (-2.47,-11.94) and (-3.28,-12.98) .. (-3.01,-13.07)
 .. controls (-2.74,-13.16) and (-3.10,-13.65) .. (-2.47,-13.38)
 .. controls (-1.84,-13.11) and (-0.64,-13.61) .. (-1.30,-12.75)
 .. controls (-2.07,-11.76) and (-2.47,-11.94) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((0.09,-11.94)
 .. controls (0.09,-11.94) and (-0.14,-12.21) .. (-0.18,-12.53)
 .. controls (-0.23,-12.84) and (-0.49,-13.02) .. (0.04,-13.02)
 .. controls (0.58,-13.02) and (0.49,-12.98) .. (0.90,-13.02)
 .. controls (1.30,-13.07) and (1.88,-13.69) .. (1.66,-12.84)
 .. controls (1.35,-11.63) and (0.49,-11.63) .. (0.49,-11.63)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((3.15,-12.12)
 .. controls (2.97,-12.17) and (2.23,-12.36) .. (2.70,-12.80)
 .. controls (3.42,-13.47) and (3.55,-13.74) .. (3.64,-13.07)
 .. controls (3.73,-12.39) and (3.33,-12.08) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((4.50,-12.55)
 .. controls (4.50,-12.55) and (4.14,-13.02) .. (4.14,-13.13)
 .. controls (4.14,-13.25) and (3.65,-14.35) .. (4.18,-14.15)
 .. controls (5.02,-13.83) and (5.20,-13.79) .. (5.22,-13.58)
 .. controls (5.24,-13.38) and (4.86,-13.31) .. (4.79,-13.22)
 .. controls (4.72,-13.13) and (4.61,-12.86) .. (4.61,-12.86)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((6.41,-13.07)
 .. controls (6.10,-13.16) and (5.83,-13.34) .. (5.71,-13.52)
 .. controls (5.60,-13.70) and (5.44,-14.21) .. (5.65,-14.26)
 .. controls (5.85,-14.30) and (5.94,-14.39) .. (6.14,-14.19)
 .. controls (6.34,-13.99) and (6.32,-14.08) .. (6.41,-13.83)
 .. controls (6.50,-13.58) and (6.61,-13.56) .. (6.57,-13.31)
 .. controls (6.52,-13.07) and (6.73,-12.98) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((7.04,-13.92)
 -- (6.61,-14.24)
 .. controls (6.61,-14.24) and (7.30,-14.98) .. (7.36,-14.80)
 .. controls (7.60,-14.01) and (7.67,-13.98) .. (7.60,-13.83)
 .. controls (7.51,-13.63) and (7.04,-13.92) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((7.99,-13.94)
 .. controls (7.92,-14.06) and (7.54,-14.28) .. (7.99,-14.57)
 .. controls (8.44,-14.87) and (8.98,-14.89) .. (8.93,-14.51)
 .. controls (8.89,-14.12) and (9.02,-14.12) .. (8.77,-13.88)
 .. controls (8.53,-13.63) and (8.05,-13.83) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((11.07,-13.70)
 .. controls (10.12,-14.33) and (10.19,-14.37) .. (10.30,-14.48)
 .. controls (10.42,-14.60) and (10.55,-14.93) .. (10.93,-14.89)
 .. controls (11.32,-14.84) and (11.47,-14.98) .. (11.45,-14.69)
 .. controls (11.43,-14.39) and (11.36,-13.88) .. (11.36,-13.88)
 -- (11.23,-13.63)
 .. controls (11.23,-13.63) and (12.01,-13.07) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((9.99,-15.79)
 .. controls (9.99,-15.79) and (9.11,-16.31) .. (9.36,-16.44)
 .. controls (9.61,-16.58) and (9.79,-17.43) .. (10.03,-17.27)
 .. controls (10.28,-17.12) and (10.46,-16.46) .. (10.53,-16.22)
 .. controls (10.60,-15.97) and (10.48,-15.61) .. (10.48,-15.61)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((8.95,-18.71)
 .. controls (8.86,-18.83) and (7.90,-19.91) .. (8.37,-20.02)
 .. controls (8.84,-20.13) and (9.65,-20.13) .. (9.65,-19.93)
 .. controls (9.65,-19.73) and (9.72,-20.22) .. (9.70,-19.59)
 .. controls (9.67,-18.96) and (9.70,-18.76) .. (9.70,-18.76)
 .. controls (9.70,-18.76) and (9.04,-18.60) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((8.98,-21.39)
 .. controls (8.98,-21.50) and (8.10,-21.64) .. (8.73,-21.95)
 .. controls (9.36,-22.27) and (9.52,-22.45) .. (9.74,-22.31)
 .. controls (9.97,-22.18) and (10.03,-21.37) .. (10.03,-21.37)
 -- (9.83,-21.17)
 .. controls (9.83,-21.17) and (8.98,-21.28) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((9.07,-22.85)
 .. controls (9.07,-22.85) and (8.80,-22.99) .. (8.84,-23.26)
 .. controls (8.89,-23.53) and (8.78,-23.91) .. (9.05,-24.07)
 .. controls (9.32,-24.23) and (9.79,-24.23) .. (9.88,-23.89)
 .. controls (9.97,-23.55) and (10.28,-23.91) .. (9.90,-23.42)
 .. controls (9.52,-22.92) and (9.36,-22.85) .. (9.36,-22.85)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((10.71,-22.76)
 .. controls (10.71,-22.76) and (9.99,-23.24) .. (10.26,-23.44)
 .. controls (10.53,-23.64) and (11.74,-23.60) .. (11.70,-23.42)
 .. controls (11.65,-23.24) and (11.72,-23.24) .. (11.63,-23.06)
 .. controls (11.54,-22.88) and (11.07,-22.56) .. (11.07,-22.56)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((10.49,-24.36)
 .. controls (10.49,-24.36) and (10.22,-24.95) .. (10.33,-24.99)
 .. controls (11.18,-25.31) and (11.13,-25.53) .. (11.36,-25.08)
 .. controls (11.68,-24.47) and (11.45,-24.43) .. (11.36,-24.38)
 .. controls (11.27,-24.34) and (10.94,-24.16) .. (10.94,-24.16)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((13.16,-18.94)
 .. controls (13.16,-18.94) and (12.35,-19.12) .. (12.51,-19.43)
 .. controls (12.67,-19.75) and (12.94,-20.02) .. (13.21,-19.93)
 .. controls (13.48,-19.84) and (13.61,-20.15) .. (13.72,-19.70)
 .. controls (13.84,-19.25) and (13.88,-18.87) .. (13.88,-18.87)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((13.12,-17.03)
 .. controls (13.12,-17.03) and (12.04,-17.75) .. (12.53,-18.02)
 .. controls (13.03,-18.29) and (13.86,-18.44) .. (13.93,-18.31)
 .. controls (13.99,-18.17) and (14.39,-18.18) .. (14.11,-17.66)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((13.12,-17.03)
 .. controls (13.12,-17.03) and (13.90,-17.14) .. (14.11,-17.66)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-23.35,-24.09)
 .. controls (-23.35,-24.09) and (-23.71,-25.58) .. (-23.53,-25.62)
 .. controls (-23.35,-25.67) and (-21.96,-26.39) .. (-21.96,-25.67)
 .. controls (-21.96,-24.95) and (-21.82,-24.63) .. (-22.14,-24.05)
 .. controls (-22.45,-23.46) and (-23.35,-24.09) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-20.83,-24.99)
 -- (-20.88,-26.97)
 .. controls (-20.88,-26.97) and (-20.88,-27.42) .. (-20.11,-26.61)
 .. controls (-19.35,-25.80) and (-19.30,-25.62) .. (-19.66,-25.31)
 .. controls (-20.02,-24.99) and (-20.83,-24.99) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-22.18,-29.54)
 .. controls (-22.18,-30.17) and (-21.50,-31.11) .. (-20.78,-30.57)
 .. controls (-20.06,-30.03) and (-19.66,-30.17) .. (-20.02,-29.40)
 .. controls (-20.38,-28.64) and (-20.60,-28.14) .. (-21.01,-28.28)
 .. controls (-21.41,-28.41) and (-22.18,-28.91) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-17.64,-23.19)
 .. controls (-17.64,-23.19) and (-18.67,-23.91) .. (-18.04,-24.14)
 .. controls (-17.41,-24.36) and (-17.14,-25.13) .. (-16.78,-24.09)
 .. controls (-16.42,-23.06) and (-16.38,-22.38) .. (-16.83,-22.47)
 .. controls (-17.28,-22.56) and (-17.64,-23.19) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-14.26,-19.32)
 .. controls (-14.26,-19.32) and (-15.79,-19.82) .. (-15.70,-20.49)
 .. controls (-15.61,-21.17) and (-15.57,-21.39) .. (-14.58,-21.21)
 .. controls (-13.59,-21.03) and (-12.96,-20.45) .. (-13.14,-19.86)
 .. controls (-13.32,-19.28) and (-14.26,-19.32) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-15.39,-22.11)
 .. controls (-15.93,-23.06) and (-16.06,-23.51) .. (-15.75,-23.69)
 .. controls (-15.43,-23.87) and (-14.85,-24.77) .. (-14.53,-23.91)
 .. controls (-14.22,-23.06) and (-13.90,-22.25) .. (-14.35,-22.11)
 .. controls (-14.80,-21.98) and (-14.85,-21.17) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-10.39,-16.85)
 .. controls (-11.02,-17.66) and (-10.89,-18.29) .. (-10.89,-18.29)
 -- (-9.85,-17.88)
 .. controls (-9.85,-17.88) and (-9.00,-17.66) .. (-9.13,-16.98)
 .. controls (-9.27,-16.31) and (-9.58,-16.04) .. (-9.81,-16.08)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-9.81,-16.08)
 -- (-10.39,-16.85)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((13.25,-21.30)
 .. controls (13.07,-21.39) and (12.73,-21.89) .. (12.85,-21.98)
 .. controls (12.96,-22.07) and (12.73,-22.49) .. (13.21,-22.34)
 .. controls (13.68,-22.18) and (14.18,-21.98) .. (14.13,-21.91)
 .. controls (13.86,-21.53) and (13.54,-21.19) .. (13.54,-21.19)
 .. controls (13.54,-21.19) and (13.43,-21.21) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((13.84,-23.73)
 .. controls (13.75,-23.78) and (13.21,-23.75) .. (13.45,-23.98)
 .. controls (13.70,-24.20) and (13.57,-24.54) .. (14.06,-24.52)
 .. controls (14.56,-24.50) and (14.87,-24.65) .. (14.96,-24.41)
 .. controls (15.05,-24.16) and (15.19,-24.16) .. (15.10,-23.93)
 .. controls (15.01,-23.71) and (15.19,-23.46) .. (15.01,-23.48)
 .. controls (14.83,-23.51) and (14.04,-23.75) .. (14.04,-23.75)
 .. controls (14.04,-23.75) and (13.93,-23.69) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((10.13,-27.15)
 .. controls (10.06,-27.24) and (9.90,-27.60) .. (10.19,-27.60)
 .. controls (10.49,-27.60) and (10.24,-27.55) .. (10.78,-27.49)
 .. controls (11.32,-27.42) and (11.66,-27.58) .. (11.70,-27.24)
 .. controls (11.75,-26.90) and (11.79,-26.43) .. (11.79,-26.43)
 .. controls (11.79,-26.43) and (11.38,-26.16) .. (11.07,-26.32)
 .. controls (10.58,-26.56) and (10.22,-27.04) .. (10.22,-27.04)
 .. controls (10.22,-27.04) and (10.19,-27.06) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((17.05,-6.86)
 .. controls (17.05,-7.13) and (16.69,-8.07) .. (17.23,-8.16)
 .. controls (17.77,-8.25) and (17.82,-8.79) .. (18.04,-8.34)
 .. controls (18.27,-7.89) and (18.45,-7.35) .. (18.45,-7.35)
 .. controls (18.45,-7.35) and (17.05,-6.59) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((15.84,-6.23)
 -- (15.43,-6.81)
 .. controls (15.43,-6.81) and (15.79,-7.08) .. (15.97,-7.04)
 .. controls (16.15,-6.99) and (16.51,-6.63) .. (16.38,-6.36)
 .. controls (16.24,-6.09) and (15.84,-6.23) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((19.57,-7.76)
 .. controls (19.57,-7.76) and (18.72,-8.61) .. (19.26,-8.70)
 .. controls (19.80,-8.79) and (20.47,-8.66) .. (20.47,-8.66)
 .. controls (20.47,-8.66) and (20.38,-8.34) .. (20.25,-8.21)
 .. controls (20.11,-8.07) and (19.57,-7.76) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((24.34,-10.86)
 -- (23.31,-10.86)
 .. controls (23.31,-10.86) and (23.40,-11.49) .. (23.58,-11.63)
 .. controls (23.76,-11.76) and (24.34,-12.48) .. (24.57,-12.26)
 .. controls (24.79,-12.03) and (24.34,-10.86) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((24.52,-12.62)
 .. controls (24.52,-12.62) and (24.43,-13.07) .. (23.98,-13.16)
 .. controls (23.53,-13.25) and (22.90,-13.29) .. (23.31,-13.92)
 .. controls (23.71,-14.55) and (24.70,-14.78) .. (24.75,-14.28)
 .. controls (24.79,-13.79) and (25.02,-13.74) .. (24.97,-13.29)
 .. controls (24.93,-12.84) and (24.52,-12.62) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((23.94,-16.13)
 .. controls (23.94,-16.13) and (23.49,-16.94) .. (23.76,-16.94)
 .. controls (24.03,-16.94) and (24.52,-17.16) .. (24.52,-16.94)
 .. controls (24.52,-16.71) and (24.70,-16.22) .. (24.75,-15.90)
 .. controls (24.79,-15.59) and (24.48,-15.14) .. (24.30,-15.41)
 .. controls (24.12,-15.68) and (23.94,-16.13) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((25.83,-18.64)
 .. controls (26.10,-19.68) and (26.95,-19.50) .. (26.95,-19.50)
 -- (26.82,-18.10)
 .. controls (26.82,-18.10) and (26.86,-17.65) .. (26.64,-17.83)
 .. controls (26.14,-18.24) and (25.65,-18.06) .. (25.65,-18.06)
 .. controls (25.65,-18.06) and (25.56,-17.61) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((24.61,-19.01)
 .. controls (24.61,-19.01) and (24.70,-19.77) .. (24.97,-19.72)
 .. controls (25.24,-19.68) and (25.45,-19.22) .. (25.29,-19.00)
 .. controls (24.97,-18.60) and (24.61,-18.69) .. (24.61,-18.69)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((27.58,-13.11)
 .. controls (27.58,-13.11) and (27.04,-14.28) .. (27.40,-14.51)
 .. controls (27.76,-14.73) and (27.99,-14.51) .. (27.99,-14.24)
 .. controls (27.99,-13.97) and (27.98,-13.02) .. (27.98,-13.02)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((27.67,-12.21)
 -- (27.67,-11.18)
 .. controls (27.67,-11.18) and (26.77,-10.95) .. (26.81,-11.22)
 .. controls (26.86,-11.49) and (26.68,-11.94) .. (26.95,-12.21)
 .. controls (27.22,-12.48) and (27.67,-12.21) .. cycle
));
endfig;
beginfig(216);
draw_upscrap(1)(1,((-27.99,-24.09)
 .. controls (-27.09,-26.07) and (-25.78,-25.89) .. (-25.60,-28.68)
 .. controls (-25.42,-31.47) and (-21.86,-38.49) .. (-19.97,-41.28)
 .. controls (-18.08,-44.07) and (-6.20,-40.33) .. (-3.86,-37.72)
 .. controls (-1.53,-35.11) and (3.06,-31.78) .. (4.95,-28.54)
 .. controls (6.84,-25.31) and (22.59,-33.09) .. (22.59,-33.09)
),
1,((26.28,-21.57)
 .. controls (22.95,-20.04) and (3.73,-7.17) .. (2.02,-6.09)
 .. controls (0.31,-5.01) and (-4.32,-5.42) .. (-5.58,-7.22)
 .. controls (-6.84,-9.02) and (-8.37,-9.87) .. (-8.37,-9.87)
));
draw_downscrap;
endfig;
beginfig(217);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((26.28,-21.57)
 .. controls (22.95,-20.04) and (3.73,-7.17) .. (2.02,-6.09)
 .. controls (0.31,-5.01) and (-4.32,-5.42) .. (-5.58,-7.22)
 .. controls (-6.84,-9.02) and (-8.37,-9.87) .. (-8.37,-9.87)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-2.57,6.05)
 -- (-2.57,38.62)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-27.99,-24.09)
 .. controls (-27.09,-26.07) and (-25.78,-25.89) .. (-25.60,-28.68)
 .. controls (-25.42,-31.47) and (-21.86,-38.49) .. (-19.97,-41.28)
 .. controls (-18.08,-44.07) and (-6.20,-40.33) .. (-3.86,-37.72)
 .. controls (-1.53,-35.11) and (3.06,-31.78) .. (4.95,-28.54)
 .. controls (6.84,-25.31) and (22.59,-33.09) .. (22.59,-33.09)
));
endfig;
beginfig(218);
drawoptions();
p_label.top(btex \thlabel\thnormalsize \thfb\char67 \char97 \char115 \char99 \char97 \char100 \char101 \ \char82 \char111 \char98 \char111 \char99 \char111 \char112 \char58 \ \char67 \char49 \char49 \mainfont{} etex,(-2.40,45.28),0.0,0);
endfig;
background:=(0.58000,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.58000, 0.25000, 1.00000);
current_scrap := "D35_20161012SP10@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP10";
beginfig(219);
draw_upscrap(1)(1,((17.28,6.10)
 .. controls (16.30,5.64) and (12.82,6.73) .. (11.83,7.18)
 .. controls (10.84,7.63) and (8.19,7.54) .. (5.04,10.06)
 .. controls (1.89,12.58) and (-8.37,13.34) .. (-8.37,13.34)
),
1,((-11.97,-2.18)
 .. controls (-11.97,-2.18) and (-6.25,-2.14) .. (-5.62,-4.84)
 .. controls (-4.99,-7.54) and (-3.24,-6.77) .. (-2.34,-8.12)
));
draw_downscrap;
endfig;
beginfig(220);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.97,-2.18)
 .. controls (-11.97,-2.18) and (-6.25,-2.14) .. (-5.62,-4.84)
 .. controls (-4.99,-7.54) and (-3.24,-6.77) .. (-2.34,-8.12)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((17.28,6.10)
 .. controls (16.30,5.64) and (12.82,6.73) .. (11.83,7.18)
 .. controls (10.84,7.63) and (8.19,7.54) .. (5.04,10.06)
 .. controls (1.89,12.58) and (-8.37,13.34) .. (-8.37,13.34)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-15.84,6.68)
 .. controls (-15.84,6.68) and (-8.55,2.95) .. (-6.30,1.69)
 .. controls (-4.05,0.43) and (0.59,-3.40) .. (1.49,-4.30)
));
ATTR__height := -1;
drawoptions();
l_pit(((18.94,6.01)
 .. controls (18.94,6.01) and (17.37,4.84) .. (15.66,5.29)
 .. controls (13.95,5.74) and (10.53,6.32) .. (8.32,7.40)
 .. controls (6.12,8.48) and (4.05,10.15) .. (3.11,10.37)
 .. controls (2.16,10.60) and (-3.60,11.99) .. (-5.67,11.86)
 .. controls (-7.74,11.72) and (-10.13,10.91) .. (-13.59,10.10)
 .. controls (-17.05,9.29) and (-18.94,7.36) .. (-15.25,4.12)
 .. controls (-11.57,0.88) and (-9.63,-0.20) .. (-6.93,-1.64)
 .. controls (-4.23,-3.08) and (-2.74,-3.62) .. (-0.90,-6.14)
 .. controls (0.95,-8.66) and (2.25,-12.31) .. (2.30,-13.34)
));
endfig;
background:=(0.55000,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.55000, 0.25000, 1.00000);
current_scrap := "D35_20161012SP9@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP9";
beginfig(221);
draw_upscrap(1)(1,((19.69,7.54)
 .. controls (14.02,7.99) and (9.74,4.12) .. (6.23,2.77)
 .. controls (2.72,1.42) and (-3.35,1.64) .. (-5.24,1.37)
 .. controls (-7.13,1.10) and (-19.69,1.51) .. (-19.69,1.51)
),
1,((-11.23,-4.93)
 .. controls (-11.23,-4.93) and (-3.94,-5.11) .. (-2.14,-5.20)
 .. controls (-0.34,-5.29) and (4.30,-6.28) .. (5.56,-5.74)
 .. controls (6.82,-5.20) and (10.46,-2.05) .. (11.99,-2.95)
 .. controls (13.52,-3.85) and (12.58,-7.81) .. (16.09,-7.99)
));
draw_downscrap;
endfig;
beginfig(222);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.23,-4.93)
 .. controls (-11.23,-4.93) and (-3.94,-5.11) .. (-2.14,-5.20)
 .. controls (-0.34,-5.29) and (4.30,-6.28) .. (5.56,-5.74)
 .. controls (6.82,-5.20) and (10.46,-2.05) .. (11.99,-2.95)
 .. controls (13.52,-3.85) and (12.58,-7.81) .. (16.09,-7.99)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((19.69,7.54)
 .. controls (14.02,7.99) and (9.74,4.12) .. (6.23,2.77)
 .. controls (2.72,1.42) and (-3.35,1.64) .. (-5.24,1.37)
 .. controls (-7.13,1.10) and (-19.69,1.51) .. (-19.69,1.51)
));
endfig;
beginfig(223);
drawoptions();
p_label.ulft(btex \thaltitude \thfb\char57 \char53 \char52 \mainfont{} etex,(10.91,5.47),0.0,1);
endfig;
background:=(0.50500,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.50500, 0.25000, 1.00000);
current_scrap := "D35_20161012SP8@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP8";
beginfig(224);
ATTR__height := -1;
drawoptions();
l_rockborder(((-5.11,-20.86)
 .. controls (-5.11,-20.86) and (-5.96,-22.52) .. (-5.51,-22.52)
 .. controls (-5.06,-22.52) and (-5.15,-22.84) .. (-4.79,-22.30)
 .. controls (-4.43,-21.76) and (-3.71,-21.26) .. (-4.16,-20.77)
 .. controls (-4.61,-20.27) and (-5.11,-20.86) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-9.52,-27.97)
 .. controls (-9.61,-28.28) and (-9.43,-29.23) .. (-9.20,-29.27)
 .. controls (-8.98,-29.32) and (-8.48,-29.14) .. (-8.17,-28.46)
 .. controls (-7.85,-27.79) and (-8.30,-27.38) .. (-8.30,-27.38)
 .. controls (-8.30,-27.38) and (-9.43,-27.65) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-0.56,-14.33)
 -- (-0.97,-16.36)
 .. controls (-0.97,-16.36) and (-0.16,-16.76) .. (-0.02,-16.45)
 .. controls (0.11,-16.13) and (0.52,-16.04) .. (0.52,-15.46)
 .. controls (0.52,-14.87) and (0.79,-14.20) .. (0.47,-13.88)
 .. controls (0.16,-13.57) and (-0.56,-14.33) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-10.51,-36.79)
 .. controls (-10.51,-36.79) and (-11.05,-37.24) .. (-10.91,-37.73)
 .. controls (-10.78,-38.23) and (-9.43,-38.81) .. (-9.20,-37.96)
 .. controls (-8.98,-37.10) and (-9.25,-36.56) .. (-9.47,-36.20)
 .. controls (-9.70,-35.84) and (-10.51,-36.79) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-16.67,-30.40)
 -- (-17.21,-31.70)
 .. controls (-17.21,-31.70) and (-17.53,-32.51) .. (-16.63,-31.97)
 .. controls (-15.73,-31.43) and (-15.28,-31.34) .. (-15.37,-30.85)
 .. controls (-15.46,-30.35) and (-15.82,-30.40) .. (-15.95,-30.17)
 .. controls (-16.09,-29.95) and (-16.67,-30.40) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-9.16,20.59)
 .. controls (-9.16,20.59) and (-8.17,19.19) .. (-4.30,20.18)
 .. controls (-0.43,21.17) and (1.73,20.86) .. (2.95,22.48)
 .. controls (4.16,24.10) and (6.01,24.82) .. (3.13,25.49)
 .. controls (0.25,26.17) and (-1.87,26.21) .. (-2.63,26.30)
 .. controls (-3.40,26.39) and (-6.91,25.99) .. (-8.08,25.94)
 .. controls (-9.25,25.90) and (-11.50,25.40) .. (-11.72,25.04)
 .. controls (-11.95,24.68) and (-9.16,20.59) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-19.69,23.96)
 .. controls (-19.69,23.96) and (-21.17,21.62) .. (-21.35,21.49)
 .. controls (-21.53,21.35) and (-21.17,19.64) .. (-21.17,19.64)
 .. controls (-21.17,19.64) and (-19.15,21.31) .. (-18.56,21.26)
 .. controls (-17.98,21.22) and (-16.40,23.47) .. (-16.54,23.60)
 .. controls (-16.67,23.74) and (-19.69,23.96) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-13.48,20.90)
 .. controls (-13.93,20.63) and (-15.73,19.37) .. (-16.27,18.83)
 .. controls (-16.81,18.29) and (-16.99,16.36) .. (-16.99,16.36)
 .. controls (-16.99,16.36) and (-16.67,14.65) .. (-16.13,14.65)
 .. controls (-15.59,14.65) and (-13.39,14.92) .. (-13.07,15.91)
 .. controls (-12.76,16.90) and (-12.08,17.98) .. (-11.95,18.83)
 .. controls (-11.81,19.69) and (-11.86,21.67) .. (-12.08,21.67)
 .. controls (-12.31,21.67) and (-13.03,21.17) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-6.23,17.44)
 .. controls (-6.64,17.44) and (-9.20,15.64) .. (-9.43,15.23)
 .. controls (-9.65,14.83) and (-9.74,11.99) .. (-9.70,11.81)
 .. controls (-9.65,11.63) and (-11.00,10.10) .. (-10.42,9.56)
 .. controls (-9.83,9.02) and (-5.78,6.73) .. (-5.33,6.77)
 .. controls (-4.88,6.82) and (-2.45,6.95) .. (-2.18,7.54)
 .. controls (-1.91,8.12) and (-1.46,10.60) .. (-1.24,11.50)
 .. controls (-1.01,12.40) and (-0.92,15.59) .. (-0.79,15.86)
 .. controls (-0.65,16.13) and (-3.71,17.39) .. (-3.71,17.39)
 .. controls (-3.71,17.39) and (-5.83,17.44) .. cycle
));
endfig;
beginfig(225);
draw_upscrap(1)(1,((-24.05,-39.44)
 .. controls (-24.05,-39.44) and (-22.84,-38.77) .. (-20.95,-35.80)
 .. controls (-19.06,-32.83) and (-17.35,-29.59) .. (-15.73,-26.80)
 .. controls (-14.11,-24.01) and (-11.05,-17.89) .. (-9.61,-16.27)
 .. controls (-8.17,-14.65) and (-6.19,-12.76) .. (-5.38,-11.05)
 .. controls (-4.57,-9.34) and (-4.88,-9.61) .. (-7.85,-6.37)
 .. controls (-10.82,-3.13) and (-13.70,1.01) .. (-15.05,2.09)
 .. controls (-16.40,3.17) and (-12.62,7.30) .. (-16.04,9.97)
 .. controls (-32.42,22.75) and (-26.71,26.26) .. (-20.59,28.87)
 .. controls (-14.47,31.48) and (-6.73,27.43) .. (-6.01,27.61)
 .. controls (-5.29,27.79) and (10.55,27.38) .. (18.74,27.47)
),
1,reverse ((2.86,-13.57)
 .. controls (2.86,-13.57) and (1.82,-8.30) .. (1.46,-7.76)
 .. controls (1.10,-7.22) and (-5.65,-4.75) .. (-5.47,-3.85)
 .. controls (-5.29,-2.95) and (-2.90,0.16) .. (-0.65,-2.36)
 .. controls (1.60,-4.88) and (2.27,-5.74) .. (2.63,-4.66)
 .. controls (2.99,-3.58) and (1.78,9.56) .. (1.69,11.99)
 .. controls (1.60,14.42) and (3.53,15.86) .. (6.41,17.57)
 .. controls (9.29,19.28) and (14.24,19.69) .. (15.86,19.87)
 .. controls (17.48,20.05) and (25.76,21.49) .. (27.20,21.04)
),
1,reverse ((-15.95,-49.93)
 .. controls (-15.95,-49.93) and (-12.89,-43.49) .. (-11.90,-42.50)
 .. controls (-10.91,-41.51) and (-5.42,-39.80) .. (-4.52,-34.58)
 .. controls (-3.62,-29.36) and (-1.87,-23.78) .. (-1.15,-22.70)
 .. controls (-0.43,-21.62) and (4.03,-17.53) .. (2.86,-13.57)
));
draw_downscrap;
endfig;
beginfig(226);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-15.95,-49.93)
 .. controls (-15.95,-49.93) and (-12.89,-43.49) .. (-11.90,-42.50)
 .. controls (-10.91,-41.51) and (-5.42,-39.80) .. (-4.52,-34.58)
 .. controls (-3.62,-29.36) and (-1.87,-23.78) .. (-1.15,-22.70)
 .. controls (-0.43,-21.62) and (4.03,-17.53) .. (2.86,-13.57)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-13.66,-33.01)
 .. controls (-13.66,-33.01) and (-11.14,-27.29) .. (-7.99,-22.16)
 .. controls (-4.84,-17.03) and (-3.08,-12.85) .. (-2.99,-10.60)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((17.08,23.74)
 .. controls (17.08,23.74) and (30.71,25.09) .. (32.42,25.18)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-24.05,-39.44)
 .. controls (-24.05,-39.44) and (-22.84,-38.77) .. (-20.95,-35.80)
 .. controls (-19.06,-32.83) and (-17.35,-29.59) .. (-15.73,-26.80)
 .. controls (-14.11,-24.01) and (-11.05,-17.89) .. (-9.61,-16.27)
 .. controls (-8.17,-14.65) and (-6.19,-12.76) .. (-5.38,-11.05)
 .. controls (-4.57,-9.34) and (-4.88,-9.61) .. (-7.85,-6.37)
 .. controls (-10.82,-3.13) and (-13.70,1.01) .. (-15.05,2.09)
 .. controls (-16.40,3.17) and (-12.62,7.30) .. (-16.04,9.97)
 .. controls (-32.42,22.75) and (-26.71,26.26) .. (-20.59,28.87)
 .. controls (-14.47,31.48) and (-6.73,27.43) .. (-6.01,27.61)
 .. controls (-5.29,27.79) and (10.55,27.38) .. (18.74,27.47)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-17.53,35.71)
 -- (-27.07,45.97)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2.86,-13.57)
 .. controls (2.86,-13.57) and (1.82,-8.30) .. (1.46,-7.76)
 .. controls (1.10,-7.22) and (-5.65,-4.75) .. (-5.47,-3.85)
 .. controls (-5.29,-2.95) and (-2.90,0.16) .. (-0.65,-2.36)
 .. controls (1.60,-4.88) and (2.27,-5.74) .. (2.63,-4.66)
 .. controls (2.99,-3.58) and (1.78,9.56) .. (1.69,11.99)
 .. controls (1.60,14.42) and (3.53,15.86) .. (6.41,17.57)
 .. controls (9.29,19.28) and (14.24,19.69) .. (15.86,19.87)
 .. controls (17.48,20.05) and (25.76,21.49) .. (27.20,21.04)
));
endfig;
beginfig(227);
drawoptions();
p_label.lrt(btex \thaltitude \thfb\char57 \char54 \char50 \mainfont{} etex,(-5.87,-37.96),0.0,1);
drawoptions();
p_label.top(btex \thlabel\thnormalsize \thfb\char84 \char114 \thfc\char233 \thfb\char109 \char105 \char101 \ \thfc\char233 \thfb\char110 \char111 \char114 \char109 \char101 \char44 \ \char66 \char105 \char118 \char111 \char117 \char97 \char99 \ \char112 \char111 \char115 \char115 \char105 \char98 \char108 \char101 \mainfont{} etex,(-30.67,49.93),0.0,0);
endfig;
background:=(0.49000,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.49000, 0.25000, 1.00000);
current_scrap := "D35_20161012SP7@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP7";
beginfig(228);
current_src := "D35_20161012.th2 [1198]";
string area_border[];
area_border[1] := "l181-2869-5893";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-46.82,3.96)
 -- (-39.26,-29.21)
 -- (-20.41,-21.01)
 .. controls (-20.41,-21.01) and (-18.79,5.18) .. (-22.30,7.88)
 .. controls (-25.81,10.57) and (-46.82,3.96) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_rockborder(((-18.34,2.34)
 .. controls (-18.74,1.67) and (-18.83,-0.09) .. (-18.83,-0.09)
 .. controls (-18.83,-0.09) and (-17.84,-0.40) .. (-17.44,0.23)
 .. controls (-17.03,0.86) and (-16.76,0.72) .. (-17.08,1.71)
 .. controls (-17.39,2.70) and (-17.93,3.02) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-15.46,5.72)
 .. controls (-15.50,5.36) and (-15.77,4.59) .. (-15.23,4.59)
 .. controls (-14.69,4.59) and (-13.97,4.73) .. (-14.02,5.09)
 .. controls (-14.06,5.45) and (-14.33,6.08) .. (-14.33,6.08)
 .. controls (-14.33,6.08) and (-15.41,6.08) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-12.40,3.78)
 .. controls (-12.40,3.78) and (-14.42,2.25) .. (-13.43,1.89)
 .. controls (-12.44,1.53) and (-11.41,1.40) .. (-11.54,1.80)
 .. controls (-11.68,2.21) and (-11.41,3.15) .. (-11.50,3.42)
 .. controls (-11.59,3.69) and (-12.40,3.78) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-5.15,15.08)
 .. controls (-5.87,14.85) and (-5.96,13.91) .. (-5.51,13.91)
 .. controls (-5.06,13.91) and (-4.43,13.37) .. (-4.48,13.64)
 .. controls (-4.52,13.91) and (-3.98,14.49) .. (-4.03,14.76)
 .. controls (-4.07,15.03) and (-4.03,15.12) .. (-4.39,15.12)
 .. controls (-4.75,15.12) and (-4.43,15.30) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((16.00,19.98)
 .. controls (15.82,19.80) and (15.28,19.71) .. (15.50,19.62)
 .. controls (15.73,19.53) and (16.04,18.81) .. (16.04,18.81)
 .. controls (16.04,18.81) and (16.53,18.17) .. (16.49,18.90)
 .. controls (16.40,20.84) and (16.18,20.16) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((7.13,18.36)
 .. controls (6.86,18.32) and (6.23,18.00) .. (6.77,17.78)
 .. controls (7.31,17.55) and (7.94,17.15) .. (8.17,17.46)
 .. controls (8.39,17.78) and (8.30,18.59) .. (8.30,18.59)
 .. controls (8.30,18.59) and (7.40,18.41) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((0.43,16.02)
 .. controls (0.25,15.62) and (0.20,14.63) .. (0.61,14.58)
 .. controls (1.01,14.54) and (2.45,14.27) .. (2.41,15.08)
 .. controls (2.36,15.89) and (2.50,16.07) .. (2.14,16.16)
 .. controls (1.78,16.25) and (0.61,16.43) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-4.48,25.43)
 .. controls (-5.02,25.16) and (-5.15,23.67) .. (-4.75,23.67)
 .. controls (-4.34,23.67) and (-3.80,23.45) .. (-3.85,23.94)
 .. controls (-3.89,24.44) and (-3.71,25.65) .. (-3.71,25.65)
 .. controls (-3.71,25.65) and (-3.94,25.70) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((28.33,15.26)
 .. controls (27.97,14.99) and (27.65,14.22) .. (28.24,14.04)
 .. controls (28.82,13.86) and (29.23,13.10) .. (29.54,13.55)
 .. controls (29.86,14.00) and (29.90,14.85) .. (29.68,15.03)
 .. controls (29.45,15.21) and (28.96,15.39) .. (28.96,15.39)
 .. controls (28.96,15.39) and (28.69,15.53) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((40.34,19.22)
 .. controls (39.94,18.54) and (39.62,17.46) .. (40.07,17.55)
 .. controls (40.52,17.64) and (40.79,17.42) .. (40.93,17.91)
 .. controls (41.06,18.41) and (40.88,18.59) .. (40.75,18.81)
 .. controls (40.61,19.04) and (40.75,19.89) .. cycle
));
endfig;
beginfig(229);
draw_upscrap(1)(1,((-39.04,-19.08)
 .. controls (-39.04,-19.08) and (-27.97,-12.06) .. (-26.35,-10.98)
 .. controls (-24.73,-9.90) and (-14.92,-7.69) .. (-13.21,-6.34)
 .. controls (-11.50,-4.99) and (-12.89,-4.05) .. (-10.46,2.07)
 .. controls (-8.03,8.19) and (-7.81,7.02) .. (-2.59,10.44)
 .. controls (2.63,13.86) and (5.02,15.12) .. (12.94,14.22)
 .. controls (20.86,13.32) and (31.39,8.01) .. (32.92,7.47)
 .. controls (34.45,6.93) and (37.96,6.48) .. (41.11,10.26)
 .. controls (44.26,14.04) and (46.82,18.05) .. (46.82,18.05)
),
1,((38.72,28.53)
 .. controls (38.72,28.53) and (35.84,22.95) .. (27.29,22.14)
 .. controls (18.74,21.33) and (10.33,21.02) .. (1.96,25.07)
 .. controls (-6.41,29.12) and (-7.09,29.21) .. (-10.60,24.35)
 .. controls (-14.11,19.49) and (-11.41,14.94) .. (-14.20,12.51)
 .. controls (-16.99,10.08) and (-20.72,3.11) .. (-23.15,0.77)
 .. controls (-25.58,-1.58) and (-27.20,-4.50) .. (-29.81,-5.76)
 .. controls (-32.42,-7.02) and (-33.91,-9.09) .. (-42.64,-9.00)
));
draw_downscrap;
endfig;
beginfig(230);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-39.04,-19.08)
 .. controls (-39.04,-19.08) and (-27.97,-12.06) .. (-26.35,-10.98)
 .. controls (-24.73,-9.90) and (-14.92,-7.69) .. (-13.21,-6.34)
 .. controls (-11.50,-4.99) and (-12.89,-4.05) .. (-10.46,2.07)
 .. controls (-8.03,8.19) and (-7.81,7.02) .. (-2.59,10.44)
 .. controls (2.63,13.86) and (5.02,15.12) .. (12.94,14.22)
 .. controls (20.86,13.32) and (31.39,8.01) .. (32.92,7.47)
 .. controls (34.45,6.93) and (37.96,6.48) .. (41.11,10.26)
 .. controls (44.26,14.04) and (46.82,18.05) .. (46.82,18.05)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((38.72,28.53)
 .. controls (38.72,28.53) and (35.84,22.95) .. (27.29,22.14)
 .. controls (18.74,21.33) and (10.33,21.02) .. (1.96,25.07)
 .. controls (-6.41,29.12) and (-7.09,29.21) .. (-10.60,24.35)
 .. controls (-14.11,19.49) and (-11.41,14.94) .. (-14.20,12.51)
 .. controls (-16.99,10.08) and (-20.72,3.11) .. (-23.15,0.77)
 .. controls (-25.58,-1.58) and (-27.20,-4.50) .. (-29.81,-5.76)
 .. controls (-32.42,-7.02) and (-33.91,-9.09) .. (-42.64,-9.00)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-10.60,9.59)
 .. controls (-10.60,9.59) and (-7.90,11.93) .. (-7.45,14.27)
 .. controls (-7.00,16.61) and (-7.13,20.88) .. (1.24,20.16)
));
endfig;
beginfig(231);
drawoptions();
p_label.lrt(btex \thaltitude \thfb\char57 \char54 \char52 \mainfont{} etex,(-18.88,-8.59),0.0,1);
endfig;
background:=(0.44500,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.44500, 0.25000, 1.00000);
current_scrap := "D35_20161012SP6@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP6";
beginfig(232);
current_src := "D35_20161012.th2 [947]";
string area_border[];
area_border[1] := "l170-2704-5754";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-42.52,-32.06)
 .. controls (-42.52,-32.06) and (-52.15,-54.07) .. (-35.95,-60.19)
 .. controls (-19.75,-66.31) and (-16.02,-56.32) .. (-16.02,-56.32)
 -- (-18.81,-31.21)
 -- cycle
)));
ATTR__height := -1;
drawoptions();
l_pit(((-47.34,-29.27)
 .. controls (-47.34,-29.27) and (-52.87,-49.03) .. (-43.06,-59.92)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-58.99,4.48)
 .. controls (-58.99,4.48) and (-61.42,4.57) .. (-61.74,4.25)
 .. controls (-62.05,3.94) and (-62.73,3.04) .. (-62.19,2.95)
 .. controls (-61.65,2.86) and (-60.34,2.81) .. (-59.98,2.81)
 .. controls (-59.62,2.81) and (-59.17,2.41) .. (-58.68,2.63)
 .. controls (-58.18,2.86) and (-57.10,2.63) .. (-57.33,3.04)
 .. controls (-57.55,3.44) and (-57.91,3.89) .. (-57.91,3.89)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-61.02,3.80)
 -- (-59.71,3.71)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-62.77,106.94)
 -- (-63.31,106.18)
 -- (-63.71,105.50)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-67.09,101.63)
 -- (-67.40,100.69)
 -- (-67.81,100.06)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-68.44,108.34)
 -- (-69.20,107.44)
));
endfig;
beginfig(233);
draw_upscrap(1)(1,((-70.51,54.47)
 .. controls (-70.51,54.47) and (-67.63,26.98) .. (-67.18,23.38)
 .. controls (-66.73,19.78) and (-63.99,11.54) .. (-63.99,6.95)
 .. controls (-63.99,2.36) and (-63.76,-5.74) .. (-63.40,-9.16)
 .. controls (-63.04,-12.58) and (-63.04,-21.62) .. (-61.15,-26.48)
 .. controls (-59.26,-31.34) and (-61.42,-41.92) .. (-60.07,-44.62)
 .. controls (-58.72,-47.32) and (-53.55,-53.57) .. (-52.74,-55.64)
 .. controls (-51.93,-57.71) and (-50.80,-61.00) .. (-48.46,-60.46)
 .. controls (-46.12,-59.92) and (-41.89,-56.86) .. (-37.57,-56.23)
 .. controls (-33.25,-55.60) and (-27.85,-51.32) .. (-26.50,-50.69)
 .. controls (-25.15,-50.06) and (-18.40,-48.94) .. (-17.50,-48.22)
),
1,((-21.10,-38.14)
 .. controls (-21.10,-38.14) and (-23.08,-36.88) .. (-27.49,-37.60)
 .. controls (-31.90,-38.32) and (-34.56,-39.98) .. (-36.90,-40.34)
),
1,((-36.90,-40.34)
 .. controls (-36.90,-40.34) and (-44.59,-39.89) .. (-45.94,-37.64)
 .. controls (-47.29,-35.39) and (-48.60,-32.87) .. (-48.96,-29.09)
 .. controls (-49.32,-25.31) and (-50.49,-24.46) .. (-51.12,-19.42)
 .. controls (-51.75,-14.38) and (-52.24,-12.80) .. (-51.70,-10.82)
 .. controls (-51.16,-8.84) and (-50.35,-1.78) .. (-50.17,0.20)
 .. controls (-49.99,2.18) and (-50.91,7.22) .. (-46.98,3.76)
),
1,((-46.98,3.76)
 .. controls (-46.98,3.76) and (-44.50,-0.97) .. (-43.78,3.62)
 .. controls (-43.06,8.21) and (-44.64,15.50) .. (-44.91,18.02)
 .. controls (-45.18,20.54) and (-46.08,24.46) .. (-46.08,24.46)
),
1,((-50.49,23.87)
 .. controls (-48.69,12.08) and (-52.24,17.98) .. (-52.51,19.15)
 .. controls (-52.78,20.32) and (-54.31,25.99) .. (-54.31,25.99)
),
1,((-54.31,25.99)
 .. controls (-55.39,31.12) and (-57.64,35.93) .. (-58.27,39.17)
 .. controls (-58.90,42.41) and (-60.79,47.45) .. (-60.79,47.45)
),
1,((-60.79,47.45)
 .. controls (-61.11,48.80) and (-63.18,55.24) .. (-63.27,56.90)
 .. controls (-63.36,58.57) and (-63.58,66.71) .. (-63.49,68.60)
 .. controls (-63.40,70.49) and (-64.66,77.56) .. (-64.75,79.85)
 .. controls (-64.84,82.15) and (-64.48,88.99) .. (-64.03,91.51)
 .. controls (-63.58,94.03) and (-60.79,100.82) .. (-60.07,101.94)
 .. controls (-59.35,103.07) and (-59.08,102.84) .. (-59.53,104.33)
 .. controls (-59.98,105.81) and (-60.65,106.49) .. (-61.01,107.52)
 .. controls (-61.37,108.56) and (-63.49,111.13) .. (-64.48,112.12)
 .. controls (-65.47,113.11) and (-67.09,118.06) .. (-67.09,118.06)
),
1,((-81.35,106.18)
 .. controls (-81.22,106.04) and (-79.33,103.66) .. (-78.97,100.60)
 .. controls (-78.61,97.54) and (-76.94,95.24) .. (-75.64,92.95)
 .. controls (-74.33,90.65) and (-72.04,88.40) .. (-71.23,86.11)
 .. controls (-70.42,83.81) and (-70.24,72.25) .. (-70.24,71.08)
 .. controls (-70.24,69.91) and (-70.87,61.99) .. (-70.60,59.60)
 .. controls (-70.33,57.22) and (-70.51,54.47) .. (-70.51,54.47)
));
draw_downscrap;
endfig;
beginfig(234);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-60.79,47.45)
 .. controls (-61.11,48.80) and (-63.18,55.24) .. (-63.27,56.90)
 .. controls (-63.36,58.57) and (-63.58,66.71) .. (-63.49,68.60)
 .. controls (-63.40,70.49) and (-64.66,77.56) .. (-64.75,79.85)
 .. controls (-64.84,82.15) and (-64.48,88.99) .. (-64.03,91.51)
 .. controls (-63.58,94.03) and (-60.79,100.82) .. (-60.07,101.94)
 .. controls (-59.35,103.07) and (-59.08,102.84) .. (-59.53,104.33)
 .. controls (-59.98,105.81) and (-60.65,106.49) .. (-61.01,107.52)
 .. controls (-61.37,108.56) and (-63.49,111.13) .. (-64.48,112.12)
 .. controls (-65.47,113.11) and (-67.09,118.06) .. (-67.09,118.06)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-67.18,95.02)
 .. controls (-67.18,95.02) and (-67.90,84.35) .. (-67.90,81.20)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-63.99,37.78)
 .. controls (-63.99,37.33) and (-61.24,23.74) .. (-61.15,21.04)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-58.72,-10.51)
 .. controls (-58.72,-10.51) and (-57.51,-22.25) .. (-55.98,-26.21)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-57.15,-36.92)
 .. controls (-57.15,-36.92) and (-53.71,-45.52) .. (-49.27,-52.58)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-69.83,109.10)
 -- (-69.83,105.68)
 -- (-67.49,107.12)
 -- (-67.76,109.64)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-64.43,107.39)
 -- (-64.61,104.60)
 -- (-63.26,104.87)
 -- (-61.73,106.49)
 -- (-62.45,107.75)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-69.02,100.73)
 -- (-68.21,98.66)
 -- (-65.87,100.37)
 -- (-67.13,102.62)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-81.35,106.18)
 .. controls (-81.22,106.04) and (-79.33,103.66) .. (-78.97,100.60)
 .. controls (-78.61,97.54) and (-76.94,95.24) .. (-75.64,92.95)
 .. controls (-74.33,90.65) and (-72.04,88.40) .. (-71.23,86.11)
 .. controls (-70.42,83.81) and (-70.24,72.25) .. (-70.24,71.08)
 .. controls (-70.24,69.91) and (-70.87,61.99) .. (-70.60,59.60)
 .. controls (-70.33,57.22) and (-70.51,54.47) .. (-70.51,54.47)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-70.51,54.47)
 .. controls (-70.51,54.47) and (-67.63,26.98) .. (-67.18,23.38)
 .. controls (-66.73,19.78) and (-63.99,11.54) .. (-63.99,6.95)
 .. controls (-63.99,2.36) and (-63.76,-5.74) .. (-63.40,-9.16)
 .. controls (-63.04,-12.58) and (-63.04,-21.62) .. (-61.15,-26.48)
 .. controls (-59.26,-31.34) and (-61.42,-41.92) .. (-60.07,-44.62)
 .. controls (-58.72,-47.32) and (-53.55,-53.57) .. (-52.74,-55.64)
 .. controls (-51.93,-57.71) and (-50.80,-61.00) .. (-48.46,-60.46)
 .. controls (-46.12,-59.92) and (-41.89,-56.86) .. (-37.57,-56.23)
 .. controls (-33.25,-55.60) and (-27.85,-51.32) .. (-26.50,-50.69)
 .. controls (-25.15,-50.06) and (-18.40,-48.94) .. (-17.50,-48.22)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-21.10,-38.14)
 .. controls (-21.10,-38.14) and (-23.08,-36.88) .. (-27.49,-37.60)
 .. controls (-31.90,-38.32) and (-34.56,-39.98) .. (-36.90,-40.34)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-54.31,25.99)
 .. controls (-55.39,31.12) and (-57.64,35.93) .. (-58.27,39.17)
 .. controls (-58.90,42.41) and (-60.79,47.45) .. (-60.79,47.45)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-36.90,-40.34)
 .. controls (-36.90,-40.34) and (-44.59,-39.89) .. (-45.94,-37.64)
 .. controls (-47.29,-35.39) and (-48.60,-32.87) .. (-48.96,-29.09)
 .. controls (-49.32,-25.31) and (-50.49,-24.46) .. (-51.12,-19.42)
 .. controls (-51.75,-14.38) and (-52.24,-12.80) .. (-51.70,-10.82)
 .. controls (-51.16,-8.84) and (-50.35,-1.78) .. (-50.17,0.20)
 .. controls (-49.99,2.18) and (-50.91,7.22) .. (-46.98,3.76)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-46.98,3.76)
 .. controls (-46.98,3.76) and (-44.50,-0.97) .. (-43.78,3.62)
 .. controls (-43.06,8.21) and (-44.64,15.50) .. (-44.91,18.02)
 .. controls (-45.18,20.54) and (-46.08,24.46) .. (-46.08,24.46)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-50.49,23.87)
 .. controls (-48.69,12.08) and (-52.24,17.98) .. (-52.51,19.15)
 .. controls (-52.78,20.32) and (-54.31,25.99) .. (-54.31,25.99)
));
ATTR__height := -1;
drawoptions();
l_pit(((-50.17,0.20)
 .. controls (-50.26,2.18) and (-51.97,7.22) .. (-51.61,9.29)
 .. controls (-51.25,11.36) and (-52.51,19.15) .. (-52.51,19.15)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-42.16,10.46)
 -- (-13.77,38.63)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-17.37,-49.70)
 -- (3.96,-71.26)
));
endfig;
beginfig(235);
ATTR__height := -1;
drawoptions();
l_label(btex \thhugesize \thfb\char82 {}\char105 {}\char118 {}\char105 {}\accent18 \char101 {}\char114 {}\char101 {}\ \char45 {}\ \char49 {}\char48 {}\char48 {}\char48 {}\mainfont{} etex,((-123.03,-46.06)
 .. controls (-123.03,-46.06) and (-96.03,-118.06) .. (-50.40,-113.65)
 .. controls (-4.77,-109.24) and (58.41,-101.05) .. (67.50,-92.23)
 .. controls (76.59,-83.41) and (112.86,-47.32) .. (123.03,-43.09)
));
drawoptions();
p_label.lft(btex \thaltitude \thfb\char57 \char55 \char48 \mainfont{} etex,(-63.99,0.52),0.0,1);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char69 \char115 \char99 \char97 \char108 \char97 \char100 \char101 \ \char100 \char101 \ \char50 \char48 \char48 \char57 \mainfont{} etex,(-10.98,40.97),0.0,0);
drawoptions();
p_label.lrt(btex \thlabel\thnormalsize \thfb\char80 \char97 \char116 \char101 \char97 \char117 \char103 \char111 \char105 \char114 \char101 \mainfont{} etex,(7.92,-74.68),0.0,0);
endfig;
background:=(0.41500,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.41500, 0.25000, 1.00000);
current_scrap := "D35_20161012SP5@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP5";
beginfig(236);
current_src := "D35_20161012.th2 [770]";
string area_border[];
area_border[1] := "l185-1889-7682";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((21.62,-13.68)
 .. controls (21.62,-13.68) and (14.02,3.87) .. (23.38,20.52)
 .. controls (32.74,37.17) and (13.57,27.72) .. (13.57,27.72)
 -- (2.05,21.87)
 .. controls (2.05,21.87) and (8.44,0.18) .. (6.55,-5.31)
 .. controls (4.66,-10.80) and (4.21,-7.65) .. (4.21,-7.65)
 .. controls (4.21,-7.65) and (0.16,-4.50) .. (-1.46,2.52)
 .. controls (-4.15,14.14) and (-1.46,14.76) .. (-5.78,12.06)
 .. controls (-8.84,10.15) and (-17.80,10.03) .. (-19.55,8.37)
 .. controls (-21.26,6.75) and (-23.69,0.19) .. (-20.81,-1.98)
 .. controls (-17.94,-4.15) and (-0.35,-8.64) .. (2.23,-6.12)
 .. controls (6.01,-2.43) and (21.62,-13.68) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_rockborder(((-1.01,14.04)
 -- (-0.92,12.15)
 .. controls (-0.92,12.15) and (0.97,11.61) .. (1.06,12.06)
 .. controls (1.15,12.51) and (1.42,15.30) .. (1.42,15.30)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((5.02,14.67)
 -- (5.29,13.68)
 -- (7.90,13.05)
 -- (7.09,14.49)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((8.35,14.22)
 -- (8.48,13.23)
 -- (9.83,13.19)
 .. controls (9.83,13.19) and (10.28,13.64) .. (10.15,13.95)
 .. controls (10.01,14.27) and (8.35,14.22) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((11.18,14.18)
 -- (10.78,13.41)
 .. controls (10.78,13.41) and (11.68,12.83) .. (11.95,13.10)
 .. controls (12.22,13.37) and (12.53,13.86) .. (12.53,13.86)
 .. controls (12.53,13.86) and (11.90,14.18) .. (11.63,14.18)
 .. controls (11.36,14.18) and (11.18,14.18) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((14.20,14.49)
 -- (13.25,13.41)
 -- (14.47,13.14)
 .. controls (14.47,13.14) and (15.26,13.10) .. (15.28,13.46)
 .. controls (15.32,14.31) and (15.01,14.58) .. (15.01,14.58)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((16.94,13.95)
 -- (16.31,13.32)
 -- (17.71,13.01)
 -- (18.43,13.32)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((18.43,13.32)
 -- (18.20,14.04)
 -- (16.94,13.95)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((19.42,14.58)
 -- (19.64,13.28)
 -- (20.41,14.67)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-1.73,9.36)
 -- (-1.19,7.56)
 -- (-0.65,6.48)
 -- (-0.02,8.37)
 -- (-0.56,10.89)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((1.69,9.00)
 -- (1.06,7.38)
 -- (1.87,6.21)
 -- (3.31,7.83)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-0.02,2.88)
 -- (-0.02,1.35)
 -- (0.70,0.45)
 .. controls (0.70,0.45) and (1.42,1.08) .. (1.42,1.80)
 .. controls (1.42,2.52) and (1.33,4.05) .. (1.33,4.05)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((2.77,-0.90)
 -- (1.96,-2.97)
 -- (3.76,-2.97)
 -- (3.49,-0.09)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((3.04,3.60)
 .. controls (3.04,3.06) and (3.58,1.80) .. (3.58,1.80)
 -- (4.66,4.14)
 -- (4.03,4.86)
 .. controls (4.03,4.86) and (3.04,4.14) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((27.88,5.67)
 -- (27.88,3.78)
 .. controls (27.88,3.78) and (30.76,2.70) .. (30.67,3.60)
 .. controls (30.58,4.50) and (30.40,6.48) .. (30.40,6.48)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((30.76,-3.33)
 .. controls (30.76,-3.33) and (30.31,-6.21) .. (30.67,-6.03)
 .. controls (31.03,-5.85) and (31.93,-5.40) .. (31.93,-5.40)
 -- (32.38,-3.51)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((37.33,-3.78)
 -- (36.88,-4.27)
 -- (36.25,-5.04)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((37.42,0.36)
 -- (37.15,-0.22)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((36.11,6.17)
 -- (36.92,5.85)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((29.05,4.95)
 -- (29.68,4.77)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((23.92,5.31)
 -- (23.92,6.48)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((21.71,-3.15)
 -- (22.75,-2.52)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((26.80,-4.50)
 -- (27.20,-3.55)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((31.30,-4.00)
 -- (31.16,-5.08)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((6.28,14.13)
 -- (7.09,13.73)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-0.47,13.28)
 -- (-0.47,13.86)
 -- (0.38,14.18)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-0.79,8.96)
 -- (-0.88,8.37)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((1.64,7.88)
 -- (1.51,7.43)
 -- (1.87,7.11)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((3.80,4.05)
 -- (3.76,3.24)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((0.56,2.70)
 -- (0.61,1.53)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((2.99,-1.57)
 -- (2.54,-2.38)
));
endfig;
beginfig(237);
draw_upscrap(1)(1,((40.07,0.95)
 .. controls (40.07,0.95) and (39.26,2.79) .. (38.14,5.00)
 .. controls (37.01,7.20) and (38.23,8.73) .. (31.84,7.56)
 .. controls (25.45,6.39) and (25.81,6.98) .. (24.32,8.19)
 .. controls (22.84,9.41) and (22.30,11.52) .. (21.76,12.51)
 .. controls (21.22,13.50) and (19.19,16.92) .. (17.39,17.96)
 .. controls (15.59,18.99) and (11.00,19.98) .. (9.79,19.94)
 .. controls (8.57,19.89) and (6.91,19.98) .. (5.20,19.53)
 .. controls (3.49,19.08) and (1.69,18.00) .. (-0.70,17.14)
 .. controls (-3.08,16.29) and (-8.71,13.68) .. (-9.74,13.14)
 .. controls (-10.78,12.60) and (-14.02,13.18) .. (-14.69,12.46)
 .. controls (-15.37,11.74) and (-17.03,11.65) .. (-17.84,11.34)
 .. controls (-18.65,11.02) and (-23.42,11.29) .. (-23.42,11.29)
),
1,((-24.46,-6.17)
 .. controls (-24.46,-6.17) and (-20.41,-8.64) .. (-18.34,-8.78)
 .. controls (-16.27,-8.91) and (-14.74,-9.63) .. (-13.70,-10.26)
 .. controls (-12.67,-10.89) and (-5.92,-13.27) .. (-3.85,-11.02)
 .. controls (-1.78,-8.77) and (-0.52,-6.21) .. (0.65,-5.31)
 .. controls (1.82,-4.41) and (3.22,-4.36) .. (6.55,-5.31)
 .. controls (9.88,-6.25) and (15.28,-6.84) .. (16.76,-7.20)
 .. controls (18.25,-7.56) and (19.55,-8.14) .. (19.87,-9.04)
 .. controls (20.18,-9.94) and (24.37,-9.63) .. (25.81,-10.93)
));
draw_downscrap;
endfig;
beginfig(238);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-24.46,-6.17)
 .. controls (-24.46,-6.17) and (-20.41,-8.64) .. (-18.34,-8.78)
 .. controls (-16.27,-8.91) and (-14.74,-9.63) .. (-13.70,-10.26)
 .. controls (-12.67,-10.89) and (-5.92,-13.27) .. (-3.85,-11.02)
 .. controls (-1.78,-8.77) and (-0.52,-6.21) .. (0.65,-5.31)
 .. controls (1.82,-4.41) and (3.22,-4.36) .. (6.55,-5.31)
 .. controls (9.88,-6.25) and (15.28,-6.84) .. (16.76,-7.20)
 .. controls (18.25,-7.56) and (19.55,-8.14) .. (19.87,-9.04)
 .. controls (20.18,-9.94) and (24.37,-9.63) .. (25.81,-10.93)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((40.07,0.95)
 .. controls (40.07,0.95) and (39.26,2.79) .. (38.14,5.00)
 .. controls (37.01,7.20) and (38.23,8.73) .. (31.84,7.56)
 .. controls (25.45,6.39) and (25.81,6.98) .. (24.32,8.19)
 .. controls (22.84,9.41) and (22.30,11.52) .. (21.76,12.51)
 .. controls (21.22,13.50) and (19.19,16.92) .. (17.39,17.96)
 .. controls (15.59,18.99) and (11.00,19.98) .. (9.79,19.94)
 .. controls (8.57,19.89) and (6.91,19.98) .. (5.20,19.53)
 .. controls (3.49,19.08) and (1.69,18.00) .. (-0.70,17.14)
 .. controls (-3.08,16.29) and (-8.71,13.68) .. (-9.74,13.14)
 .. controls (-10.78,12.60) and (-14.02,13.18) .. (-14.69,12.46)
 .. controls (-15.37,11.74) and (-17.03,11.65) .. (-17.84,11.34)
 .. controls (-18.65,11.02) and (-23.42,11.29) .. (-23.42,11.29)
));
ATTR__height := -1;
drawoptions();
l_pit(((-9.20,11.88)
 .. controls (-9.20,11.88) and (-13.79,10.08) .. (-18.65,10.44)
 .. controls (-23.51,10.80) and (-28.73,9.54) .. (-27.83,6.30)
 .. controls (-26.93,3.06) and (-30.76,-0.27) .. (-30.22,-1.17)
 .. controls (-29.68,-2.07) and (-29.18,-3.56) .. (-20.81,-6.08)
 .. controls (-12.44,-8.60) and (-13.48,-9.18) .. (-10.06,-9.00)
 .. controls (-6.64,-8.82) and (-7.27,-9.90) .. (-5.65,-8.55)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-16.49,-13.55)
 -- (-35.39,-33.03)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((37.06,1.44)
 -- (35.89,-0.81)
 -- (37.96,-1.08)
 .. controls (37.96,-1.08) and (38.32,-0.18) .. (38.50,0.81)
 .. controls (38.68,1.80) and (37.06,1.44) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((34.72,-5.31)
 -- (35.89,-6.66)
 -- (39.13,-4.23)
 -- (37.51,-2.79)
 -- (36.07,-4.23)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((35.08,6.75)
 -- (35.35,4.50)
 -- (37.24,5.31)
 -- (37.06,6.57)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((20.95,-2.61)
 -- (21.40,-4.50)
 -- (24.73,-2.88)
 -- (23.02,-1.17)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((25.90,-5.40)
 -- (26.17,-2.79)
 -- (28.87,-2.97)
 -- (27.79,-5.31)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((23.29,7.47)
 -- (22.75,4.32)
 -- (25.27,4.68)
 -- (25.00,7.47)
 -- cycle
));
endfig;
beginfig(239);
drawoptions();
p_label.lrt(btex \thaltitude \thfb\char57 \char55 \char52 \mainfont{} etex,(-3.22,-10.39),0.0,1);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char67 \char97 \char115 \char99 \char97 \char100 \char101 \ \char100 \char101 \ \char108 \char97 \ \char106 \char111 \char110 \char99 \char116 \char105 \char111 \char110 \ \char68 \char51 \char53 \ \char45 \ \char70 \char114 \char111 \char109 \char97 \char103 \accent18 \char101 \char114 \char101 \char58 \ \char67 \char49 \char56 \mainfont{} etex,(-40.07,-37.17),0.0,0);
endfig;
background:=(0.28750,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.28750, 0.25000, 1.00000);
current_scrap := "D35_20161012SP4@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP4";
beginfig(240);
current_src := "D35_20161012.th2 [464]";
string area_border[];
area_border[1] := "l240-1445-7377";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((12.83,3.53)
 .. controls (12.83,3.53) and (8.24,2.81) .. (7.43,1.55)
 .. controls (6.62,0.29) and (3.28,-6.37) .. (7.79,-8.44)
 .. controls (12.29,-10.51) and (9.14,-8.80) .. (10.31,-9.70)
 .. controls (11.48,-10.60) and (14.18,-10.87) .. (14.18,-10.87)
 -- cycle
)));
endfig;
beginfig(241);
draw_upscrap(1)(1,((-14.18,7.99)
 .. controls (-14.18,7.99) and (-13.10,6.50) .. (-12.33,5.15)
 .. controls (-11.57,3.80) and (-10.94,2.81) .. (-9.09,1.60)
 .. controls (-7.25,0.38) and (-1.53,-0.38) .. (-2.21,-2.14)
 .. controls (-2.88,-3.89) and (-8.78,-5.92) .. (-5.36,-8.35)
 .. controls (-1.94,-10.78) and (1.71,-11.54) .. (2.97,-12.35)
),
1,((4.27,5.02)
 .. controls (3.91,4.93) and (3.73,5.15) .. (2.07,5.47)
 .. controls (0.41,5.78) and (0.32,5.33) .. (-1.44,5.83)
 .. controls (-3.19,6.32) and (-4.09,6.37) .. (-4.50,7.67)
 .. controls (-4.90,8.98) and (-5.67,12.17) .. (-5.67,12.17)
));
draw_downscrap;
endfig;
beginfig(242);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.27,5.02)
 .. controls (3.91,4.93) and (3.73,5.15) .. (2.07,5.47)
 .. controls (0.41,5.78) and (0.32,5.33) .. (-1.44,5.83)
 .. controls (-3.19,6.32) and (-4.09,6.37) .. (-4.50,7.67)
 .. controls (-4.90,8.98) and (-5.67,12.17) .. (-5.67,12.17)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-11.75,12.35)
 .. controls (-11.75,12.35) and (-8.28,6.77) .. (-6.75,5.15)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-14.18,7.99)
 .. controls (-14.18,7.99) and (-13.10,6.50) .. (-12.33,5.15)
 .. controls (-11.57,3.80) and (-10.94,2.81) .. (-9.09,1.60)
 .. controls (-7.25,0.38) and (-1.53,-0.38) .. (-2.21,-2.14)
 .. controls (-2.88,-3.89) and (-8.78,-5.92) .. (-5.36,-8.35)
 .. controls (-1.94,-10.78) and (1.71,-11.54) .. (2.97,-12.35)
));
endfig;
background:=(0.27250,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.27250, 0.25000, 1.00000);
current_scrap := "D35_20161012SP3@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP3";
beginfig(243);
current_src := "D35_20161012.th2 [332]";
string area_border[];
area_border[1] := "l166-1304-8022";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((37.71,15.84)
 .. controls (37.71,15.84) and (21.06,26.59) .. (20.34,28.39)
 .. controls (19.62,30.19) and (-4.02,4.77) .. (13.41,2.52)
 .. controls (30.15,0.36) and (33.93,2.88) .. (33.93,2.88)
 -- cycle
)));
ATTR__height := -1;
drawoptions();
l_rockborder(((20.34,-16.02)
 .. controls (19.26,-16.02) and (20.07,-19.89) .. (20.07,-19.89)
 -- (20.92,-21.91)
 -- (23.49,-23.71)
 .. controls (23.49,-23.71) and (25.68,-24.13) .. (25.56,-23.31)
 .. controls (25.33,-21.78) and (24.30,-19.66) .. (24.30,-19.66)
 .. controls (24.30,-19.66) and (23.94,-16.02) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((20.52,-17.28)
 .. controls (20.52,-17.28) and (21.64,-18.72) .. (21.64,-18.31)
 .. controls (21.64,-17.91) and (22.14,-16.87) .. (22.14,-16.87)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((21.64,-18.31)
 .. controls (21.64,-18.31) and (22.50,-19.84) .. (22.54,-20.16)
 .. controls (22.59,-20.47) and (23.17,-22.36) .. (23.17,-22.36)
));
endfig;
beginfig(244);
draw_upscrap(1)(1,((30.73,-26.10)
 .. controls (30.73,-26.10) and (29.92,-23.35) .. (29.29,-21.51)
 .. controls (28.66,-19.66) and (25.47,-13.41) .. (24.16,-12.60)
 .. controls (22.86,-11.79) and (22.09,-8.51) .. (21.78,-8.15)
 .. controls (21.46,-7.79) and (20.34,-4.77) .. (20.47,-3.06)
 .. controls (20.61,-1.35) and (19.62,0.13) .. (19.62,1.26)
 .. controls (19.62,2.38) and (19.39,3.55) .. (19.80,4.45)
 .. controls (20.20,5.35) and (21.01,8.10) .. (20.92,9.00)
 .. controls (20.83,9.90) and (22.45,14.17) .. (24.57,15.21)
 .. controls (26.68,16.24) and (26.28,17.91) .. (28.08,18.09)
 .. controls (29.88,18.27) and (30.96,18.85) .. (31.27,19.53)
 .. controls (31.59,20.20) and (34.69,21.51) .. (35.64,21.64)
),
1,((24.57,23.58)
 .. controls (24.57,23.58) and (23.45,22.14) .. (22.95,21.73)
 .. controls (22.46,21.33) and (20.79,20.11) .. (20.70,19.84)
 .. controls (20.61,19.57) and (18.14,19.75) .. (17.06,19.71)
 .. controls (15.98,19.66) and (14.40,19.66) .. (12.42,17.77)
 .. controls (10.44,15.88) and (9.81,12.01) .. (10.71,7.56)
 .. controls (11.61,3.10) and (11.92,1.03) .. (12.19,-0.32)
 .. controls (12.46,-1.67) and (12.42,-3.78) .. (12.46,-5.26)
 .. controls (12.51,-6.75) and (10.89,-14.22) .. (15.79,-18.09)
),
1,((15.79,-18.09)
 .. controls (15.79,-18.09) and (18.40,-20.38) .. (16.87,-19.93)
 .. controls (15.34,-19.48) and (12.78,-19.44) .. (12.78,-19.44)
 -- (10.48,-19.71)
),
1,((11.47,-25.83)
 .. controls (11.47,-25.83) and (14.98,-25.11) .. (15.79,-25.11)
 .. controls (16.60,-25.11) and (18.81,-25.24) .. (19.62,-25.96)
 .. controls (20.43,-26.68) and (20.52,-27.99) .. (20.97,-28.35)
 .. controls (21.42,-28.71) and (22.00,-30.19) .. (22.00,-30.19)
));
draw_downscrap;
endfig;
beginfig(245);
ATTR__height := -1;
drawoptions();
l_rockedge(((5.13,-21.96)
 -- (-30.15,-21.96)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((24.57,23.58)
 .. controls (24.57,23.58) and (23.45,22.14) .. (22.95,21.73)
 .. controls (22.46,21.33) and (20.79,20.11) .. (20.70,19.84)
 .. controls (20.61,19.57) and (18.14,19.75) .. (17.06,19.71)
 .. controls (15.98,19.66) and (14.40,19.66) .. (12.42,17.77)
 .. controls (10.44,15.88) and (9.81,12.01) .. (10.71,7.56)
 .. controls (11.61,3.10) and (11.92,1.03) .. (12.19,-0.32)
 .. controls (12.46,-1.67) and (12.42,-3.78) .. (12.46,-5.26)
 .. controls (12.51,-6.75) and (10.89,-14.22) .. (15.79,-18.09)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((15.79,-18.09)
 .. controls (15.79,-18.09) and (18.40,-20.38) .. (16.87,-19.93)
 .. controls (15.34,-19.48) and (12.78,-19.44) .. (12.78,-19.44)
 -- (10.48,-19.71)
));
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((6.34,-24.30),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.47,-25.83)
 .. controls (11.47,-25.83) and (14.98,-25.11) .. (15.79,-25.11)
 .. controls (16.60,-25.11) and (18.81,-25.24) .. (19.62,-25.96)
 .. controls (20.43,-26.68) and (20.52,-27.99) .. (20.97,-28.35)
 .. controls (21.42,-28.71) and (22.00,-30.19) .. (22.00,-30.19)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((30.73,-26.10)
 .. controls (30.73,-26.10) and (29.92,-23.35) .. (29.29,-21.51)
 .. controls (28.66,-19.66) and (25.47,-13.41) .. (24.16,-12.60)
 .. controls (22.86,-11.79) and (22.09,-8.51) .. (21.78,-8.15)
 .. controls (21.46,-7.79) and (20.34,-4.77) .. (20.47,-3.06)
 .. controls (20.61,-1.35) and (19.62,0.13) .. (19.62,1.26)
 .. controls (19.62,2.38) and (19.39,3.55) .. (19.80,4.45)
 .. controls (20.20,5.35) and (21.01,8.10) .. (20.92,9.00)
 .. controls (20.83,9.90) and (22.45,14.17) .. (24.57,15.21)
 .. controls (26.68,16.24) and (26.28,17.91) .. (28.08,18.09)
 .. controls (29.88,18.27) and (30.96,18.85) .. (31.27,19.53)
 .. controls (31.59,20.20) and (34.69,21.51) .. (35.64,21.64)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((15.03,-0.18)
 .. controls (15.03,-0.18) and (16.42,-6.08) .. (16.78,-8.14)
 .. controls (17.14,-10.21) and (18.31,-9.72) .. (19.39,-12.06)
));
endfig;
beginfig(246);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char65 \char114 \char114 \char105 \char118 \thfc\char233 \thfb\char101 \ \char112 \char101 \char116 \char105 \char116 \ \char97 \char99 \char116 \char105 \char102 \ \thfc\char184 \ \thfb\char56 \char109 \ \char100 \char101 \ \char104 \char97 \char117 \char116 \mainfont{} etex,(-37.71,-21.60),0.0,0);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char57 \char57 \char52 \mainfont{} etex,(27.54,-17.55),0.0,1);
endfig;
background:=(0.25000,0.26500,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.26500, 1.00000);
current_scrap := "D35_20161012SP2@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP2";
beginfig(247);
current_src := "D35_20161012.th2 [278]";
string area_border[];
area_border[1] := "l194-1420-8261";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((20.50,3.85)
 -- (19.87,-7.31)
 .. controls (19.87,-7.31) and (17.17,-7.31) .. (16.72,-6.86)
 .. controls (16.27,-6.41) and (-0.88,-2.00) .. (1.01,3.58)
 .. controls (2.90,9.16) and (4.79,8.53) .. (5.96,7.36)
 .. controls (7.13,6.19) and (18.97,3.94) .. (20.41,5.29)
 .. controls (21.85,6.64) and (20.50,3.85) .. cycle
)));
endfig;
beginfig(248);
draw_upscrap(1)(1,((10.55,8.35)
 .. controls (10.55,8.35) and (9.29,7.09) .. (8.30,6.14)
 .. controls (7.31,5.20) and (6.19,4.61) .. (5.11,2.99)
 .. controls (4.03,1.37) and (4.84,2.18) .. (3.35,-0.25)
 .. controls (2.60,-1.48) and (0.88,-0.02) .. (0.56,-0.97)
 .. controls (0.25,-1.91) and (-0.92,-4.12) .. (-1.28,-4.48)
 .. controls (-1.64,-4.84) and (-2.63,-7.22) .. (-2.63,-7.22)
),
1,((8.44,-9.16)
 .. controls (8.44,-9.16) and (9.74,-8.80) .. (10.82,-8.44)
 .. controls (11.90,-8.08) and (13.39,-7.27) .. (13.88,-6.68)
 .. controls (14.38,-6.10) and (14.65,-5.11) .. (14.96,-4.93)
 .. controls (15.28,-4.75) and (16.67,-4.21) .. (16.67,-4.21)
),
1,((18.79,2.18)
 .. controls (17.48,2.18) and (19.10,4.30) .. (18.92,5.56)
 .. controls (18.74,6.82) and (20.54,8.44) .. (20.54,8.44)
));
draw_downscrap;
endfig;
beginfig(249);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((10.55,8.35)
 .. controls (10.55,8.35) and (9.29,7.09) .. (8.30,6.14)
 .. controls (7.31,5.20) and (6.19,4.61) .. (5.11,2.99)
 .. controls (4.03,1.37) and (4.84,2.18) .. (3.35,-0.25)
 .. controls (2.60,-1.48) and (0.88,-0.02) .. (0.56,-0.97)
 .. controls (0.25,-1.91) and (-0.92,-4.12) .. (-1.28,-4.48)
 .. controls (-1.64,-4.84) and (-2.63,-7.22) .. (-2.63,-7.22)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((4.12,9.07)
 -- (-20.09,9.07)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((18.79,2.18)
 .. controls (17.48,2.18) and (19.10,4.30) .. (18.92,5.56)
 .. controls (18.74,6.82) and (20.54,8.44) .. (20.54,8.44)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((8.44,-9.16)
 .. controls (8.44,-9.16) and (9.74,-8.80) .. (10.82,-8.44)
 .. controls (11.90,-8.08) and (13.39,-7.27) .. (13.88,-6.68)
 .. controls (14.38,-6.10) and (14.65,-5.11) .. (14.96,-4.93)
 .. controls (15.28,-4.75) and (16.67,-4.21) .. (16.67,-4.21)
));
endfig;
beginfig(250);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char80 \char51 \mainfont{} etex,(-21.85,8.98),0.0,0);
drawoptions();
p_label.ulft(btex \thaltitude \thfb\char49 \char48 \char48 \char48 \mainfont{} etex,(5.42,4.03),0.0,1);
endfig;
background:=(0.25000,0.29500,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.29500, 1.00000);
current_scrap := "D35_20161012SP1@D35_20161012.D35projet";
ATTR__scrap := "D35_20161012SP1";
beginfig(251);
current_src := "D35_20161012.th2 [181]";
string area_border[];
area_border[1] := "l168-1280-8710";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-26.49,32.35)
 .. controls (-26.49,32.35) and (-38.55,32.35) .. (-42.69,35.05)
 .. controls (-46.83,37.75) and (-50.97,29.65) .. (-50.97,29.65)
 -- (-39.99,26.77)
 -- (-30.81,24.79)
 -- (-31.71,31.09)
 -- cycle
)));
ATTR__height := -1;
drawoptions();
l_pit(((-33.24,5.31)
 .. controls (-33.24,5.31) and (-27.75,0.13) .. (-25.00,-0.63)
));
ATTR__height := -1;
drawoptions();
l_pit(((-27.97,-2.21)
 .. controls (-28.06,-2.03) and (-33.51,4.37) .. (-33.51,4.37)
 .. controls (-33.51,4.37) and (-36.12,5.27) .. (-41.11,4.77)
));
ATTR__height := -1;
drawoptions();
l_pit(((-33.06,-15.34)
 .. controls (-31.26,-12.83) and (-32.34,-6.70) .. (-32.34,-6.70)
));
endfig;
beginfig(252);
draw_upscrap(1)(1,((-62.00,119.47)
 .. controls (-62.00,119.47) and (-59.42,119.31) .. (-59.13,117.91)
 .. controls (-58.85,116.59) and (-59.20,115.84) .. (-59.42,115.17)
 .. controls (-59.64,114.50) and (-57.85,113.22) .. (-59.02,112.42)
 .. controls (-60.16,111.63) and (-60.98,111.04) .. (-61.06,110.33)
 .. controls (-61.14,109.62) and (-62.94,106.14) .. (-63.11,106.01)
 .. controls (-63.29,105.88) and (-64.95,97.28) .. (-65.00,96.73)
 .. controls (-65.05,96.19) and (-64.47,95.37) .. (-64.02,95.28)
 .. controls (-63.57,95.19) and (-62.36,94.15) .. (-62.45,93.11)
 .. controls (-62.54,92.08) and (-61.82,90.14) .. (-60.64,88.57)
 .. controls (-59.47,87.01) and (-57.06,82.59) .. (-53.13,81.93)
 .. controls (-49.21,81.27) and (-49.48,81.22) .. (-49.30,79.96)
 .. controls (-49.12,78.70) and (-45.12,74.25) .. (-44.71,73.17)
 .. controls (-44.30,72.09) and (-42.64,71.55) .. (-43.32,70.15)
 .. controls (-43.99,68.75) and (-48.59,65.64) .. (-46.74,61.23)
 .. controls (-44.90,56.82) and (-43.19,54.98) .. (-41.97,54.31)
 .. controls (-40.75,53.63) and (-38.73,51.83) .. (-38.15,50.71)
 .. controls (-37.56,49.58) and (-37.43,47.96) .. (-37.74,46.25)
 .. controls (-38.05,44.54) and (-36.88,42.07) .. (-36.88,40.54)
 .. controls (-36.88,39.01) and (-37.33,37.57) .. (-38.50,36.18)
 .. controls (-39.67,34.78) and (-36.75,31.59) .. (-39.31,32.71)
 .. controls (-41.88,33.83) and (-41.11,32.31) .. (-40.66,31.14)
 .. controls (-40.21,29.97) and (-40.89,27.04) .. (-40.44,25.87)
 .. controls (-39.99,24.70) and (-40.39,24.57) .. (-41.97,25.51)
 .. controls (-43.54,26.46) and (-45.75,26.64) .. (-44.67,24.97)
 .. controls (-43.59,23.31) and (-41.43,21.28) .. (-40.71,20.70)
 .. controls (-39.99,20.11) and (-39.58,19.71) .. (-39.99,18.31)
 .. controls (-40.39,16.92) and (-40.62,16.47) .. (-40.66,15.25)
 .. controls (-40.71,14.04) and (-40.80,12.10) .. (-40.75,10.80)
 .. controls (-40.71,9.49) and (-37.51,8.10) .. (-37.65,6.97)
 .. controls (-37.78,5.85) and (-41.70,2.61) .. (-41.29,1.57)
 .. controls (-40.89,0.54) and (-40.93,-1.26) .. (-41.02,-1.93)
),
1,((-31.03,-1.84)
 .. controls (-31.03,-1.84) and (-29.57,-0.42) .. (-28.65,0.22)
),
1,((-28.65,0.22)
 .. controls (-28.65,0.22) and (-27.70,0.72) .. (-26.76,0.67)
 .. controls (-25.81,0.63) and (-19.83,-0.23) .. (-19.60,-1.04)
),
1,((-19.60,-1.04)
 .. controls (-19.29,-3.20) and (-24.55,-5.18) .. (-26.22,-6.53)
 .. controls (-27.88,-7.88) and (-32.79,-8.10) .. (-32.79,-8.10)
),
1,((-34.90,-14.49)
 .. controls (-34.18,-14.17) and (-31.17,-13.28) .. (-29.05,-12.15)
 .. controls (-26.94,-11.03) and (-20.28,-7.07) .. (-19.56,-6.26)
 .. controls (-18.84,-5.45) and (-15.24,-2.89) .. (-13.44,-1.22)
),
1,((-13.44,-1.22)
 .. controls (-12.63,-0.64) and (-11.19,1.88) .. (-12.05,2.20)
 .. controls (-12.90,2.51) and (-14.92,4.63) .. (-17.04,4.49)
 .. controls (-19.15,4.36) and (-21.63,4.09) .. (-21.63,4.09)
),
1,((-21.63,4.09)
 .. controls (-23.34,4.32) and (-28.56,4.63) .. (-29.14,5.71)
 .. controls (-29.73,6.79) and (-18.03,12.46) .. (-16.81,13.40)
 .. controls (-15.60,14.35) and (-15.47,15.61) .. (-15.74,17.32)
 .. controls (-16.01,19.03) and (-18.61,21.55) .. (-18.84,22.76)
 .. controls (-19.07,23.98) and (-21.45,24.88) .. (-23.20,26.09)
 .. controls (-24.96,27.31) and (-30.31,28.48) .. (-30.31,28.48)
),
1,reverse ((-56.85,120.69)
 .. controls (-56.85,120.69) and (-54.35,117.14) .. (-53.81,116.21)
 .. controls (-53.24,115.25) and (-49.55,112.09) .. (-53.58,109.96)
 .. controls (-57.65,107.81) and (-56.82,107.04) .. (-56.64,105.79)
 .. controls (-56.45,104.54) and (-55.41,101.54) .. (-54.51,100.86)
 .. controls (-53.61,100.18) and (-53.24,98.34) .. (-52.93,97.31)
 .. controls (-52.61,96.28) and (-50.92,91.73) .. (-50.46,90.84)
 .. controls (-50.01,89.95) and (-47.32,84.95) .. (-47.10,84.46)
 .. controls (-46.87,83.96) and (-44.63,81.48) .. (-43.28,80.13)
 .. controls (-41.93,78.78) and (-38.96,77.38) .. (-38.15,75.22)
 .. controls (-37.34,73.06) and (-37.03,71.44) .. (-38.06,65.87)
 .. controls (-39.09,60.30) and (-37.82,60.12) .. (-36.03,58.68)
 .. controls (-34.23,57.24) and (-34.32,56.56) .. (-34.09,55.66)
 .. controls (-33.87,54.76) and (-33.56,52.28) .. (-33.20,51.92)
 .. controls (-32.84,51.56) and (-32.03,51.20) .. (-32.03,51.20)
 .. controls (-32.03,51.20) and (-31.58,50.70) .. (-31.49,49.85)
 .. controls (-31.40,48.99) and (-32.29,46.61) .. (-32.29,45.94)
 .. controls (-32.29,45.26) and (-32.52,45.08) .. (-31.75,44.09)
 .. controls (-30.99,43.10) and (-30.54,42.88) .. (-30.36,41.66)
 .. controls (-30.18,40.45) and (-29.82,37.03) .. (-32.79,34.78)
 .. controls (-35.76,32.53) and (-34.41,32.08) .. (-34.27,31.05)
 .. controls (-34.14,30.01) and (-31.53,28.80) .. (-30.31,28.48)
));
draw_upscrap(1)(1,((-33.91,4.32)
 .. controls (-33.87,5.44) and (-34.45,4.82) .. (-34.27,5.54)
 .. controls (-34.09,6.25) and (-34.63,7.92) .. (-35.49,8.28)
 .. controls (-36.34,8.64) and (-37.11,10.62) .. (-37.20,11.61)
 .. controls (-37.29,12.60) and (-39.00,13.81) .. (-38.50,14.98)
 .. controls (-38.01,16.15) and (-35.44,18.18) .. (-35.08,18.58)
 .. controls (-34.72,18.99) and (-33.91,20.25) .. (-34.54,21.42)
 .. controls (-35.17,22.59) and (-35.44,25.65) .. (-35.44,26.19)
 .. controls (-35.44,26.73) and (-35.76,28.35) .. (-35.76,28.35)
),
1,((-35.76,28.35)
 .. controls (-35.98,29.70) and (-30.00,26.77) .. (-29.14,26.05)
 .. controls (-28.29,25.33) and (-24.78,22.40) .. (-22.98,20.24)
 .. controls (-21.18,18.08) and (-21.13,14.39) .. (-23.25,12.73)
 .. controls (-25.36,11.07) and (-31.53,9.45) .. (-31.53,7.92)
),
1,((-31.53,7.92)
 .. controls (-31.53,7.92) and (-32.47,5.76) .. (-33.01,4.27)
 .. controls (-33.55,2.79) and (-33.78,3.84) .. (-33.91,4.32)
));
draw_downscrap;
endfig;
beginfig(253);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-56.85,120.69)
 .. controls (-56.85,120.69) and (-54.35,117.14) .. (-53.81,116.21)
 .. controls (-53.24,115.25) and (-49.55,112.09) .. (-53.58,109.96)
 .. controls (-57.65,107.81) and (-56.82,107.04) .. (-56.64,105.79)
 .. controls (-56.45,104.54) and (-55.41,101.54) .. (-54.51,100.86)
 .. controls (-53.61,100.18) and (-53.24,98.34) .. (-52.93,97.31)
 .. controls (-52.61,96.28) and (-50.92,91.73) .. (-50.46,90.84)
 .. controls (-50.01,89.95) and (-47.32,84.95) .. (-47.10,84.46)
 .. controls (-46.87,83.96) and (-44.63,81.48) .. (-43.28,80.13)
 .. controls (-41.93,78.78) and (-38.96,77.38) .. (-38.15,75.22)
 .. controls (-37.34,73.06) and (-37.03,71.44) .. (-38.06,65.87)
 .. controls (-39.09,60.30) and (-37.82,60.12) .. (-36.03,58.68)
 .. controls (-34.23,57.24) and (-34.32,56.56) .. (-34.09,55.66)
 .. controls (-33.87,54.76) and (-33.56,52.28) .. (-33.20,51.92)
 .. controls (-32.84,51.56) and (-32.03,51.20) .. (-32.03,51.20)
 .. controls (-32.03,51.20) and (-31.58,50.70) .. (-31.49,49.85)
 .. controls (-31.40,48.99) and (-32.29,46.61) .. (-32.29,45.94)
 .. controls (-32.29,45.26) and (-32.52,45.08) .. (-31.75,44.09)
 .. controls (-30.99,43.10) and (-30.54,42.88) .. (-30.36,41.66)
 .. controls (-30.18,40.45) and (-29.82,37.03) .. (-32.79,34.78)
 .. controls (-35.76,32.53) and (-34.41,32.08) .. (-34.27,31.05)
 .. controls (-34.14,30.01) and (-31.53,28.80) .. (-30.31,28.48)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-57.03,117.18)
 .. controls (-57.03,117.18) and (-55.97,112.92) .. (-57.74,109.77)
 .. controls (-59.43,106.76) and (-60.81,104.40) .. (-59.46,100.34)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-41.34,75.28)
 .. controls (-41.34,75.28) and (-38.91,69.60) .. (-40.08,64.65)
 .. controls (-41.25,59.71) and (-36.57,56.47) .. (-34.68,54.49)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-24.15,23.71)
 .. controls (-24.15,23.71) and (-18.57,19.66) .. (-18.66,16.96)
 .. controls (-18.75,14.26) and (-20.37,12.55) .. (-20.91,11.74)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-23.34,-6.62)
 .. controls (-23.34,-6.62) and (-28.38,-9.68) .. (-29.91,-9.95)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-34.90,-14.49)
 .. controls (-34.18,-14.17) and (-31.17,-13.28) .. (-29.05,-12.15)
 .. controls (-26.94,-11.03) and (-20.28,-7.07) .. (-19.56,-6.26)
 .. controls (-18.84,-5.45) and (-15.24,-2.89) .. (-13.44,-1.22)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-21.63,4.09)
 .. controls (-23.34,4.32) and (-28.56,4.63) .. (-29.14,5.71)
 .. controls (-29.73,6.79) and (-18.03,12.46) .. (-16.81,13.40)
 .. controls (-15.60,14.35) and (-15.47,15.61) .. (-15.74,17.32)
 .. controls (-16.01,19.03) and (-18.61,21.55) .. (-18.84,22.76)
 .. controls (-19.07,23.98) and (-21.45,24.88) .. (-23.20,26.09)
 .. controls (-24.96,27.31) and (-30.31,28.48) .. (-30.31,28.48)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-13.44,-1.22)
 .. controls (-12.63,-0.64) and (-11.19,1.88) .. (-12.05,2.20)
 .. controls (-12.90,2.51) and (-14.92,4.63) .. (-17.04,4.49)
 .. controls (-19.15,4.36) and (-21.63,4.09) .. (-21.63,4.09)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-35.76,28.35)
 .. controls (-35.98,29.70) and (-30.00,26.77) .. (-29.14,26.05)
 .. controls (-28.29,25.33) and (-24.78,22.40) .. (-22.98,20.24)
 .. controls (-21.18,18.08) and (-21.13,14.39) .. (-23.25,12.73)
 .. controls (-25.36,11.07) and (-31.53,9.45) .. (-31.53,7.92)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-31.53,7.92)
 .. controls (-31.53,7.92) and (-32.47,5.76) .. (-33.01,4.27)
 .. controls (-33.55,2.79) and (-33.78,3.84) .. (-33.91,4.32)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-19.60,-1.04)
 .. controls (-19.29,-3.20) and (-24.55,-5.18) .. (-26.22,-6.53)
 .. controls (-27.88,-7.88) and (-32.79,-8.10) .. (-32.79,-8.10)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-30.49,7.29)
 .. controls (-31.58,5.43) and (-28.78,3.15) .. (-26.67,2.74)
 .. controls (-24.55,2.34) and (-19.92,1.89) .. (-18.75,1.66)
 .. controls (-17.58,1.44) and (-16.59,0.90) .. (-16.63,0.45)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-42.96,13.23)
 -- (-66.72,13.22)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-62.00,119.47)
 .. controls (-62.00,119.47) and (-59.42,119.31) .. (-59.13,117.91)
 .. controls (-58.85,116.59) and (-59.20,115.84) .. (-59.42,115.17)
 .. controls (-59.64,114.50) and (-57.85,113.22) .. (-59.02,112.42)
 .. controls (-60.16,111.63) and (-60.98,111.04) .. (-61.06,110.33)
 .. controls (-61.14,109.62) and (-62.94,106.14) .. (-63.11,106.01)
 .. controls (-63.29,105.88) and (-64.95,97.28) .. (-65.00,96.73)
 .. controls (-65.05,96.19) and (-64.47,95.37) .. (-64.02,95.28)
 .. controls (-63.57,95.19) and (-62.36,94.15) .. (-62.45,93.11)
 .. controls (-62.54,92.08) and (-61.82,90.14) .. (-60.64,88.57)
 .. controls (-59.47,87.01) and (-57.06,82.59) .. (-53.13,81.93)
 .. controls (-49.21,81.27) and (-49.48,81.22) .. (-49.30,79.96)
 .. controls (-49.12,78.70) and (-45.12,74.25) .. (-44.71,73.17)
 .. controls (-44.30,72.09) and (-42.64,71.55) .. (-43.32,70.15)
 .. controls (-43.99,68.75) and (-48.59,65.64) .. (-46.74,61.23)
 .. controls (-44.90,56.82) and (-43.19,54.98) .. (-41.97,54.31)
 .. controls (-40.75,53.63) and (-38.73,51.83) .. (-38.15,50.71)
 .. controls (-37.56,49.58) and (-37.43,47.96) .. (-37.74,46.25)
 .. controls (-38.05,44.54) and (-36.88,42.07) .. (-36.88,40.54)
 .. controls (-36.88,39.01) and (-37.33,37.57) .. (-38.50,36.18)
 .. controls (-39.67,34.78) and (-36.75,31.59) .. (-39.31,32.71)
 .. controls (-41.88,33.83) and (-41.11,32.31) .. (-40.66,31.14)
 .. controls (-40.21,29.97) and (-40.89,27.04) .. (-40.44,25.87)
 .. controls (-39.99,24.70) and (-40.39,24.57) .. (-41.97,25.51)
 .. controls (-43.54,26.46) and (-45.75,26.64) .. (-44.67,24.97)
 .. controls (-43.59,23.31) and (-41.43,21.28) .. (-40.71,20.70)
 .. controls (-39.99,20.11) and (-39.58,19.71) .. (-39.99,18.31)
 .. controls (-40.39,16.92) and (-40.62,16.47) .. (-40.66,15.25)
 .. controls (-40.71,14.04) and (-40.80,12.10) .. (-40.75,10.80)
 .. controls (-40.71,9.49) and (-37.51,8.10) .. (-37.65,6.97)
 .. controls (-37.78,5.85) and (-41.70,2.61) .. (-41.29,1.57)
 .. controls (-40.89,0.54) and (-40.93,-1.26) .. (-41.02,-1.93)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-33.91,4.32)
 .. controls (-33.87,5.44) and (-34.45,4.82) .. (-34.27,5.54)
 .. controls (-34.09,6.25) and (-34.63,7.92) .. (-35.49,8.28)
 .. controls (-36.34,8.64) and (-37.11,10.62) .. (-37.20,11.61)
 .. controls (-37.29,12.60) and (-39.00,13.81) .. (-38.50,14.98)
 .. controls (-38.01,16.15) and (-35.44,18.18) .. (-35.08,18.58)
 .. controls (-34.72,18.99) and (-33.91,20.25) .. (-34.54,21.42)
 .. controls (-35.17,22.59) and (-35.44,25.65) .. (-35.44,26.19)
 .. controls (-35.44,26.73) and (-35.76,28.35) .. (-35.76,28.35)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-31.03,-1.84)
 .. controls (-31.03,-1.84) and (-29.57,-0.42) .. (-28.65,0.22)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-28.65,0.22)
 .. controls (-28.65,0.22) and (-27.70,0.72) .. (-26.76,0.67)
 .. controls (-25.81,0.63) and (-19.83,-0.23) .. (-19.60,-1.04)
));
endfig;
beginfig(254);
ATTR__height := -1;
drawoptions();
l_label(btex \thhugesize \thfb\char82 {}\char105 {}\char118 {}\char105 {}\accent18 \char101 {}\char114 {}\char101 {}\ \char45 {}\ \char49 {}\char48 {}\char48 {}\char48 {}\mainfont{} etex,((-2.82,115.54)
 .. controls (-2.82,115.54) and (9.66,71.35) .. (11.10,63.44)
 .. controls (12.55,55.53) and (19.94,15.05) .. (17.42,5.51)
 .. controls (14.90,-4.02) and (20.66,-28.87) .. (31.28,-51.01)
 .. controls (38.54,-66.17) and (68.68,-103.88) .. (69.07,-120.69)
));
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char80 \char97 \char115 \char115 \char97 \char103 \char101 \ \char102 \char111 \char115 \char115 \char105 \char108 \char101 \mainfont{} etex,(-69.07,13.12),0.0,0);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char48 \char48 \char55 \mainfont{} etex,(-64.29,101.28),0.0,1);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char49 \char48 \char48 \char51 \mainfont{} etex,(-30.40,42.43),0.0,1);
endfig;
background:=(0.25000,0.45250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.45250, 1.00000);
current_scrap := "D35_20161012__2_SP2@D35_20161012__2.D35projet";
ATTR__scrap := "D35_20161012__2_SP2";
beginfig(255);
ATTR__survey := "D35_20161012__2.D35projet";
current_src := "D35_20161012__2.th2 [193]";
string area_border[];
area_border[1] := "l30-193-366";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-19.72,-15.16)
 .. controls (-19.72,-15.16) and (-24.78,-15.32) .. (-25.02,-18.18)
 .. controls (-25.23,-20.81) and (-23.86,-19.41) .. (-23.59,-20.79)
 .. controls (-23.31,-22.22) and (-9.51,-39.43) .. (-9.51,-39.43)
 .. controls (-9.51,-39.43) and (-4.73,-36.03) .. (-4.48,-32.63)
 .. controls (-4.22,-29.22) and (-16.84,-20.97) .. (-17.69,-16.00)
 .. controls (-18.51,-11.17) and (-19.72,-15.16) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_floorstep(((-9.03,-26.11)
 .. controls (-9.08,-22.07) and (-15.80,-18.74) .. (-15.80,-18.74)
));
endfig;
beginfig(256);
draw_upscrap(1)(1,((-7.30,-37.30)
 .. controls (-7.30,-37.30) and (-8.76,-36.53) .. (-9.12,-36.10)
 .. controls (-9.50,-35.66) and (-10.61,-33.89) .. (-10.97,-33.31)
 .. controls (-11.35,-32.71) and (-16.97,-25.94) .. (-17.41,-25.27)
 .. controls (-17.82,-24.64) and (-21.88,-20.99) .. (-22.04,-19.90)
 .. controls (-22.19,-18.83) and (-24.18,-17.60) .. (-24.40,-17.05)
 .. controls (-24.63,-16.48) and (-25.84,-14.14) .. (-26.66,-13.75)
),
1,reverse ((-5.75,-18.96)
 .. controls (-6.45,-20.32) and (-7.26,-19.70) .. (-8.49,-20.01)
 .. controls (-9.72,-20.31) and (-10.92,-20.17) .. (-12.56,-19.57)
 .. controls (-14.11,-18.99) and (-14.45,-18.46) .. (-17.83,-17.96)
 .. controls (-20.83,-17.51) and (-20.83,-16.02) .. (-21.42,-15.28)
 .. controls (-22.09,-14.45) and (-23.20,-11.82) .. (-23.10,-11.55)
),
1,reverse ((-6.67,-26.33)
 .. controls (-6.67,-26.33) and (-4.69,-26.62) .. (-4.09,-25.91)
 .. controls (-3.49,-25.20) and (-2.27,-24.89) .. (-2.12,-23.77)
 .. controls (-1.96,-22.65) and (-1.78,-21.30) .. (-1.61,-20.71)
),
1,reverse ((-3.72,-35.21)
 .. controls (-3.72,-35.21) and (-4.86,-34.67) .. (-5.73,-33.79)
 .. controls (-6.51,-33.00) and (-7.47,-31.56) .. (-7.58,-31.08)
 .. controls (-7.70,-30.60) and (-8.52,-29.09) .. (-8.41,-28.52)
 .. controls (-8.30,-27.94) and (-9.40,-27.33) .. (-8.76,-26.07)
 .. controls (-8.13,-24.81) and (-8.04,-26.20) .. (-6.67,-26.33)
));
draw_downscrap;
endfig;
beginfig(257);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.72,-35.21)
 .. controls (-3.72,-35.21) and (-4.86,-34.67) .. (-5.73,-33.79)
 .. controls (-6.51,-33.00) and (-7.47,-31.56) .. (-7.58,-31.08)
 .. controls (-7.70,-30.60) and (-8.52,-29.09) .. (-8.41,-28.52)
 .. controls (-8.30,-27.94) and (-9.40,-27.33) .. (-8.76,-26.07)
 .. controls (-8.13,-24.81) and (-8.04,-26.20) .. (-6.67,-26.33)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-18.91,22.29)
 -- (-18.43,-16.36)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-18.91,22.29)
 -- (-7.83,37.69)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-6.67,-26.33)
 .. controls (-6.67,-26.33) and (-4.69,-26.62) .. (-4.09,-25.91)
 .. controls (-3.49,-25.20) and (-2.27,-24.89) .. (-2.12,-23.77)
 .. controls (-1.96,-22.65) and (-1.78,-21.30) .. (-1.61,-20.71)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-1.62,-25.37)
 -- (25.06,-25.55)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.30,-37.30)
 .. controls (-7.30,-37.30) and (-8.76,-36.53) .. (-9.12,-36.10)
 .. controls (-9.50,-35.66) and (-10.61,-33.89) .. (-10.97,-33.31)
 .. controls (-11.35,-32.71) and (-16.97,-25.94) .. (-17.41,-25.27)
 .. controls (-17.82,-24.64) and (-21.88,-20.99) .. (-22.04,-19.90)
 .. controls (-22.19,-18.83) and (-24.18,-17.60) .. (-24.40,-17.05)
 .. controls (-24.63,-16.48) and (-25.84,-14.14) .. (-26.66,-13.75)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.75,-18.96)
 .. controls (-6.45,-20.32) and (-7.26,-19.70) .. (-8.49,-20.01)
 .. controls (-9.72,-20.31) and (-10.92,-20.17) .. (-12.56,-19.57)
 .. controls (-14.11,-18.99) and (-14.45,-18.46) .. (-17.83,-17.96)
 .. controls (-20.83,-17.51) and (-20.83,-16.02) .. (-21.42,-15.28)
 .. controls (-22.09,-14.45) and (-23.20,-11.82) .. (-23.10,-11.55)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-27.19,-8.70)
 .. controls (-27.19,-8.70) and (-25.10,-12.67) .. (-24.91,-13.46)
 .. controls (-24.72,-14.20) and (-23.46,-15.73) .. (-23.46,-15.73)
));
endfig;
beginfig(258);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char66 \char97 \char115 \char115 \char105 \char110 \mainfont{} etex,(-6.56,39.43),0.0,0);
drawoptions();
p_label.llft(btex \thaltitude \thfb\char49 \char48 \char50 \char55 \mainfont{} etex,(-12.28,-31.98),0.0,1);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char67 \char52 \mainfont{} etex,(27.19,-25.62),0.0,0);
endfig;
background:=(0.25000,0.49750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.49750, 1.00000);
current_scrap := "D35_20161012__2_SP1@D35_20161012__2.D35projet";
ATTR__scrap := "D35_20161012__2_SP1";
beginfig(259);
current_src := "D35_20161012__2.th2 [54]";
string area_border[];
area_border[1] := "l45-502-554";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-2.70,4.52)
 .. controls (-3.51,4.52) and (-11.88,5.15) .. (-11.88,3.80)
 .. controls (-11.88,2.45) and (-12.06,-14.29) .. (-12.06,-14.29)
 .. controls (-12.06,-14.29) and (-10.44,-20.95) .. (-5.85,-21.67)
 .. controls (-1.26,-22.39) and (3.60,-2.59) .. (3.60,-2.59)
 .. controls (3.60,-2.59) and (-1.89,4.52) .. cycle
)));
endfig;
beginfig(260);
draw_upscrap(1)(1,((-9.22,-22.88)
 .. controls (-9.22,-22.88) and (-8.50,-19.91) .. (-8.28,-19.46)
 .. controls (-8.06,-19.01) and (-6.66,-16.18) .. (-6.66,-15.77)
 .. controls (-6.66,-15.37) and (-6.30,-12.58) .. (-5.98,-12.49)
 .. controls (-5.67,-12.40) and (-5.26,-11.14) .. (-3.65,-12.04)
 .. controls (-2.03,-12.94) and (-1.44,-12.04) .. (-1.67,-11.32)
 .. controls (-1.89,-10.60) and (-1.57,-8.75) .. (-1.71,-8.39)
 .. controls (-1.84,-8.03) and (-2.88,-5.11) .. (-2.97,-4.25)
 .. controls (-3.06,-3.40) and (-3.46,-0.61) .. (-3.37,0.38)
 .. controls (-3.28,1.37) and (-3.26,2.30) .. (-5.76,5.56)
),
1,((-5.76,5.56)
 .. controls (-5.76,5.56) and (-6.03,6.01) .. (-6.30,6.95)
),
1,((-9.86,5.92)
 .. controls (-9.86,5.92) and (-9.49,1.82) .. (-9.13,0.83)
 .. controls (-8.77,-0.16) and (-8.14,-2.00) .. (-7.96,-3.40)
 .. controls (-7.78,-4.79) and (-7.60,-6.82) .. (-7.47,-7.45)
 .. controls (-7.33,-8.08) and (-7.29,-8.26) .. (-7.33,-10.10)
 .. controls (-7.38,-11.95) and (-7.74,-12.26) .. (-8.05,-13.34)
 .. controls (-8.37,-14.42) and (-9.36,-16.72) .. (-10.08,-17.17)
 .. controls (-10.80,-17.62) and (-12.20,-19.24) .. (-12.56,-19.87)
 .. controls (-12.92,-20.50) and (-13.36,-21.13) .. (-13.36,-21.13)
));
draw_downscrap;
endfig;
beginfig(261);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.22,-22.88)
 .. controls (-9.22,-22.88) and (-8.50,-19.91) .. (-8.28,-19.46)
 .. controls (-8.06,-19.01) and (-6.66,-16.18) .. (-6.66,-15.77)
 .. controls (-6.66,-15.37) and (-6.30,-12.58) .. (-5.98,-12.49)
 .. controls (-5.67,-12.40) and (-5.26,-11.14) .. (-3.65,-12.04)
 .. controls (-2.03,-12.94) and (-1.44,-12.04) .. (-1.67,-11.32)
 .. controls (-1.89,-10.60) and (-1.57,-8.75) .. (-1.71,-8.39)
 .. controls (-1.84,-8.03) and (-2.88,-5.11) .. (-2.97,-4.25)
 .. controls (-3.06,-3.40) and (-3.46,-0.61) .. (-3.37,0.38)
 .. controls (-3.28,1.37) and (-3.26,2.30) .. (-5.76,5.56)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-0.90,-7.49)
 -- (13.91,-7.49)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-8.46,14.83)
 -- (-8.46,26.17)
));
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((-11.16,10.33),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-10.62,16.22)
 .. controls (-10.62,16.22) and (-9.99,13.52) .. (-9.45,11.90)
 .. controls (-8.91,10.28) and (-8.28,9.47) .. (-8.37,7.85)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((11.70,-17.84)
 -- (-6.62,-17.84)
));
ATTR__height := -1;
drawoptions();
l_pit(((-15.57,-27.02)
 .. controls (-14.85,-27.61) and (-13.95,-27.79) .. (-12.73,-27.83)
 .. controls (-11.52,-27.88) and (-10.98,-26.75) .. (-10.62,-26.03)
 .. controls (-10.26,-25.31) and (-9.67,-23.78) .. (-9.58,-21.80)
 .. controls (-9.49,-19.82) and (-10.89,-18.65) .. (-12.55,-21.04)
 .. controls (-14.22,-23.42) and (-15.62,-22.48) .. (-15.62,-22.48)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.76,5.56)
 .. controls (-5.76,5.56) and (-6.03,6.01) .. (-6.30,6.95)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.86,5.92)
 .. controls (-9.86,5.92) and (-9.49,1.82) .. (-9.13,0.83)
 .. controls (-8.77,-0.16) and (-8.14,-2.00) .. (-7.96,-3.40)
 .. controls (-7.78,-4.79) and (-7.60,-6.82) .. (-7.47,-7.45)
 .. controls (-7.33,-8.08) and (-7.29,-8.26) .. (-7.33,-10.10)
 .. controls (-7.38,-11.95) and (-7.74,-12.26) .. (-8.05,-13.34)
 .. controls (-8.37,-14.42) and (-9.36,-16.72) .. (-10.08,-17.17)
 .. controls (-10.80,-17.62) and (-12.20,-19.24) .. (-12.56,-19.87)
 .. controls (-12.92,-20.50) and (-13.36,-21.13) .. (-13.36,-21.13)
));
endfig;
beginfig(262);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char97 \char115 \ \char100 \char101 \ \char67 \char65 \char58 \ \char49 \char50 \char47 \char49 \char48 \char47 \char50 \char48 \char49 \char54 \mainfont{} etex,(15.62,-7.49),0.0,0);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char67 \char51 \char58 \ \char67 \char97 \ \char99 \char111 \char110 \char116 \char105 \char110 \char117 \char101 \ \char100 \char101 \char114 \char114 \char105 \accent18 \char101 \char114 \char101 \mainfont{} etex,(-8.42,27.88),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char86 \char111 \char117 \char116 \char101 \ \char109 \char111 \char117 \char105 \char108 \char108 \char97 \char110 \char116 \char101 \ \char100 \char101 \ \char108 \char97 \ \char98 \thfc\char233 \thfb\char113 \char117 \char105 \char108 \char108 \char101 \mainfont{} etex,(12.96,-17.89),0.0,0);
drawoptions();
p_label.ulft(btex \thaltitude \thfb\char49 \char48 \char51 \char51 \mainfont{} etex,(-9.77,-16.72),0.0,1);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char48 \char51 \char52 \mainfont{} etex,(-9.72,3.89),0.0,1);
endfig;
background:=(0.99250,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.99250, 0.25000, 1.00000);
current_scrap := "fromagereSP27bis@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP27bis";
beginfig(263);
ATTR__survey := "20161022fromagere.D35projet";
current_src := "20160711fromagere.th2 [2109]";
string area_border[];
area_border[1] := "l364-34160-20072";
area_border[2] := "l359-34094-19878";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-23.57,80.53)
 .. controls (-23.57,80.53) and (-27.62,97.74) .. (-31.13,98.54)
 .. controls (-50.04,102.87) and (-57.42,91.16) .. (-57.42,91.16)
 -- (-50.22,74.96)
),
((-23.57,80.53)
 .. controls (-39.06,62.89) and (-48.42,76.40) .. (-50.22,74.96)
)));
current_src := "20160711fromagere.th2 [2104]";
string area_border[];
area_border[1] := "l358-34764-19306";
area_border[2] := "l365-34862-19304";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((0.90,19.16)
 .. controls (0.90,19.16) and (2.88,32.84) .. (25.92,29.24)
),
((0.90,19.16)
 -- (2.16,13.94)
 .. controls (2.16,13.94) and (17.82,-1.71) .. (32.58,8.72)
 .. controls (33.77,9.56) and (40.14,20.78) .. (39.96,22.22)
 .. controls (39.78,23.66) and (25.92,29.24) .. (25.92,29.24)
)));
current_src := "20160711fromagere.th2 [2097]";
string area_border[];
area_border[1] := "l356-34378-19772";
area_border[2] := "l359-34094-19878";
area_border[3] := "l360-34000-19710";
area_border[4] := "l358-34764-19306";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_sump(buildcycle(((25.92,29.24)
 .. controls (28.08,35.90) and (-23.57,80.53) .. (-23.57,80.53)
),
((-23.57,80.53)
 .. controls (-39.06,62.89) and (-48.42,76.40) .. (-50.22,74.96)
),
((-50.22,74.96)
 .. controls (-52.02,73.52) and (-38.16,54.25) .. (-38.16,54.25)
 -- (-11.52,36.08)
 -- (0.90,19.16)
),
((0.90,19.16)
 .. controls (0.90,19.16) and (2.88,32.84) .. (25.92,29.24)
)));
ATTR__id := "l358-34764-19306";
ATTR__height := -1;
drawoptions();
l_border_visible(((0.90,19.16)
 .. controls (0.90,19.16) and (2.88,32.84) .. (25.92,29.24)
));
ATTR__id := "l359-34094-19878";
ATTR__height := -1;
drawoptions();
l_border_visible(((-23.57,80.53)
 .. controls (-39.06,62.89) and (-48.42,76.40) .. (-50.22,74.96)
));
endfig;
beginfig(264);
draw_upscrap(1)(1,((72.18,-90.45)
 .. controls (70.92,-85.77) and (51.66,-45.82) .. (47.52,-38.08)
 .. controls (43.38,-30.34) and (27.72,1.17) .. (26.28,6.57)
 .. controls (24.84,11.97) and (18.36,21.69) .. (18.00,24.03)
 .. controls (17.64,26.37) and (5.22,43.10) .. (0.54,47.24)
 .. controls (-4.14,51.38) and (-12.60,56.23) .. (-15.47,59.47)
 .. controls (-18.35,62.70) and (-19.61,66.31) .. (-23.57,70.27)
 .. controls (-27.53,74.23) and (-31.86,79.45) .. (-31.86,79.45)
),
1,((-31.86,79.45)
 .. controls (-34.38,83.06) and (-35.82,87.38) .. (-36.89,91.34)
 .. controls (-37.97,95.30) and (-49.67,110.79) .. (-51.11,122.31)
 .. controls (-52.55,133.83) and (-55.98,140.49) .. (-55.98,140.49)
),
1,((-75.42,135.28)
 .. controls (-75.42,135.28) and (-68.94,125.37) .. (-68.76,124.29)
 .. controls (-68.58,123.21) and (-64.98,117.45) .. (-60.12,110.97)
 .. controls (-55.26,104.49) and (-63.00,104.67) .. (-63.00,104.67)
),
1,((-59.94,94.95)
 .. controls (-55.26,95.85) and (-52.92,85.40) .. (-52.92,85.40)
 .. controls (-52.92,85.40) and (-45.36,71.89) .. (-44.10,67.21)
 .. controls (-42.84,62.53) and (-23.22,48.13) .. (-17.64,45.61)
 .. controls (-12.06,43.10) and (-0.90,31.04) .. (0.18,28.16)
 .. controls (1.26,25.28) and (5.76,22.23) .. (6.84,15.92)
 .. controls (7.92,9.62) and (-4.68,14.12) .. (-4.68,14.12)
),
1,reverse ((52.56,-93.69)
 .. controls (52.56,-93.69) and (49.50,-88.83) .. (42.48,-72.09)
 .. controls (35.46,-55.36) and (33.84,-46.36) .. (28.44,-37.36)
 .. controls (23.04,-28.36) and (18.36,-12.52) .. (17.10,-10.90)
 .. controls (15.84,-9.28) and (14.76,0.45) .. (8.46,1.70)
 .. controls (2.16,2.96) and (-4.14,5.66) .. (-4.14,5.66)
));
draw_downscrap;
endfig;
beginfig(265);
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-31.86,79.45)
 .. controls (-34.38,83.06) and (-35.82,87.38) .. (-36.89,91.34)
 .. controls (-37.97,95.30) and (-49.67,110.79) .. (-51.11,122.31)
 .. controls (-52.55,133.83) and (-55.98,140.49) .. (-55.98,140.49)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((72.18,-90.45)
 .. controls (70.92,-85.77) and (51.66,-45.82) .. (47.52,-38.08)
 .. controls (43.38,-30.34) and (27.72,1.17) .. (26.28,6.57)
 .. controls (24.84,11.97) and (18.36,21.69) .. (18.00,24.03)
 .. controls (17.64,26.37) and (5.22,43.10) .. (0.54,47.24)
 .. controls (-4.14,51.38) and (-12.60,56.23) .. (-15.47,59.47)
 .. controls (-18.35,62.70) and (-19.61,66.31) .. (-23.57,70.27)
 .. controls (-27.53,74.23) and (-31.86,79.45) .. (-31.86,79.45)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((52.56,-93.69)
 .. controls (52.56,-93.69) and (49.50,-88.83) .. (42.48,-72.09)
 .. controls (35.46,-55.36) and (33.84,-46.36) .. (28.44,-37.36)
 .. controls (23.04,-28.36) and (18.36,-12.52) .. (17.10,-10.90)
 .. controls (15.84,-9.28) and (14.76,0.45) .. (8.46,1.70)
 .. controls (2.16,2.96) and (-4.14,5.66) .. (-4.14,5.66)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-59.94,94.95)
 .. controls (-55.26,95.85) and (-52.92,85.40) .. (-52.92,85.40)
 .. controls (-52.92,85.40) and (-45.36,71.89) .. (-44.10,67.21)
 .. controls (-42.84,62.53) and (-23.22,48.13) .. (-17.64,45.61)
 .. controls (-12.06,43.10) and (-0.90,31.04) .. (0.18,28.16)
 .. controls (1.26,25.28) and (5.76,22.23) .. (6.84,15.92)
 .. controls (7.92,9.62) and (-4.68,14.12) .. (-4.68,14.12)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-75.42,135.28)
 .. controls (-75.42,135.28) and (-68.94,125.37) .. (-68.76,124.29)
 .. controls (-68.58,123.21) and (-64.98,117.45) .. (-60.12,110.97)
 .. controls (-55.26,104.49) and (-63.00,104.67) .. (-63.00,104.67)
));
drawoptions();
p_gradient((67.86,-112.59),196.5,2.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((41.06,101.96)
 -- (-1.79,59.65)
));
endfig;
beginfig(266);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char86 \char101 \char114 \char115 \ \char115 \char105 \char112 \char104 \char111 \char110 \ \char116 \char101 \char114 \char109 \char105 \char110 \char97 \char108 \ \char100 \char117 \ \char103 \char111 \char117 \char102 \char102 \char114 \char101 \ \char100 \char101 \ \char108 \char97 \ \char70 \char114 \char111 \char109 \char97 \char103 \accent18 \char101 \char114 \char101 \mainfont{} etex,(75.42,-140.49),0.0,0);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char83 \char105 \char112 \char104 \char111 \char110 \mainfont{} etex,(45.56,107.00),0.0,0);
endfig;
background:=(0.91000,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.91000, 0.25000, 1.00000);
current_scrap := "fromagereSP25@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP25";
beginfig(267);
current_src := "20160711fromagere.th2 [1831]";
string area_border[];
area_border[1] := "l380-33600-24782";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((35.55,188.65)
 .. controls (35.55,188.65) and (-7.65,165.43) .. (-15.39,177.67)
 .. controls (-23.13,189.91) and (-36.27,151.75) .. (-35.73,150.85)
 .. controls (-35.19,149.95) and (11.07,134.29) .. (27.27,144.01)
 .. controls (43.47,153.73) and (35.55,188.65) .. cycle
)));
current_src := "20160711fromagere.th2 [1827]";
string area_border[];
area_border[1] := "l379-33598-23798";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((35.91,100.10)
 .. controls (35.91,100.10) and (13.77,79.58) .. (-14.85,99.56)
 .. controls (-43.47,119.54) and (-15.03,53.30) .. (-15.03,53.30)
 -- (-12.33,21.44)
 .. controls (-12.33,21.44) and (-5.68,-1.29) .. (13.41,20.90)
 .. controls (20.61,29.27) and (14.22,15.77) .. (27.36,15.95)
 .. controls (40.50,16.13) and (39.87,19.46) .. (38.97,25.22)
 .. controls (38.07,30.98) and (38.97,71.48) .. (38.97,71.48)
 -- cycle
)));
ATTR__height := -1;
drawoptions();
l_rockborder(((-1.17,155.44)
 .. controls (-2.70,154.72) and (-3.06,152.29) .. (-3.06,152.29)
 .. controls (-3.06,152.29) and (-3.87,150.94) .. (-3.06,150.94)
 .. controls (-2.25,150.94) and (1.62,149.86) .. (1.71,150.67)
 .. controls (1.80,151.48) and (2.61,150.40) .. (2.79,152.92)
 .. controls (2.97,155.44) and (0.90,155.62) .. (0.90,155.62)
 .. controls (0.90,155.62) and (0.36,156.16) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((12.78,-59.92)
 .. controls (12.78,-59.92) and (15.84,-78.64) .. (16.02,-84.22)
 .. controls (16.20,-89.80) and (22.86,-95.65) .. (23.22,-87.37)
 .. controls (23.58,-79.09) and (21.87,-74.05) .. (21.69,-71.53)
 .. controls (21.51,-69.01) and (18.36,-55.42) .. (18.36,-55.42)
 -- (15.57,-55.60)
 -- cycle
));
endfig;
beginfig(268);
draw_upscrap(1)(1,((-9.99,182.71)
 .. controls (-9.99,182.71) and (-9.27,120.44) .. (-9.63,116.12)
 .. controls (-9.99,111.80) and (0.09,55.64) .. (-0.27,53.12)
 .. controls (-0.63,50.60) and (1.17,19.64) .. (0.81,12.08)
 .. controls (0.45,4.52) and (7.29,-51.28) .. (7.29,-51.28)
 .. controls (7.29,-51.28) and (19.53,-120.40) .. (19.17,-126.52)
 .. controls (18.81,-132.64) and (19.53,-141.64) .. (19.89,-145.24)
 .. controls (20.25,-148.84) and (41.49,-195.63) .. (41.49,-195.63)
),
1,((60.93,-190.41)
 .. controls (60.93,-190.41) and (50.13,-153.16) .. (48.69,-148.12)
 .. controls (47.25,-143.08) and (39.15,-113.65) .. (39.15,-113.65)
 .. controls (39.15,-113.65) and (38.61,-97.99) .. (33.93,-72.07)
 .. controls (30.54,-53.29) and (26.73,-14.20) .. (26.73,-9.52)
 .. controls (26.73,-4.84) and (26.19,24.59) .. (26.19,26.75)
 .. controls (26.19,28.91) and (25.29,38.27) .. (25.29,38.27)
 .. controls (25.29,38.27) and (23.58,57.26) .. (23.94,64.82)
 .. controls (24.30,72.38) and (22.05,84.26) .. (22.05,84.26)
 .. controls (22.05,84.26) and (16.11,121.70) .. (15.75,125.65)
 .. controls (15.39,129.61) and (15.48,147.88) .. (15.12,153.28)
 .. controls (14.76,158.68) and (14.40,185.05) .. (14.40,185.05)
));
draw_downscrap;
endfig;
beginfig(269);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((60.93,-190.41)
 .. controls (60.93,-190.41) and (50.13,-153.16) .. (48.69,-148.12)
 .. controls (47.25,-143.08) and (39.15,-113.65) .. (39.15,-113.65)
 .. controls (39.15,-113.65) and (38.61,-97.99) .. (33.93,-72.07)
 .. controls (30.54,-53.29) and (26.73,-14.20) .. (26.73,-9.52)
 .. controls (26.73,-4.84) and (26.19,24.59) .. (26.19,26.75)
 .. controls (26.19,28.91) and (25.29,38.27) .. (25.29,38.27)
 .. controls (25.29,38.27) and (23.58,57.26) .. (23.94,64.82)
 .. controls (24.30,72.38) and (22.05,84.26) .. (22.05,84.26)
 .. controls (22.05,84.26) and (16.11,121.70) .. (15.75,125.65)
 .. controls (15.39,129.61) and (15.48,147.88) .. (15.12,153.28)
 .. controls (14.76,158.68) and (14.40,185.05) .. (14.40,185.05)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((1.71,138.79)
 .. controls (1.71,138.79) and (4.41,128.53) .. (5.13,124.93)
 .. controls (5.85,121.34) and (7.29,114.68) .. (8.01,109.28)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((35.01,-129.04)
 .. controls (35.01,-129.04) and (37.89,-137.32) .. (38.97,-142.90)
 .. controls (40.05,-148.48) and (38.97,-153.16) .. (42.39,-161.62)
 .. controls (45.81,-170.07) and (49.95,-176.01) .. (49.95,-176.01)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((19.17,12.26)
 .. controls (19.17,12.26) and (22.05,8.84) .. (18.63,2.18)
 .. controls (15.21,-4.48) and (13.77,-14.74) .. (15.93,-23.20)
 .. controls (18.09,-31.66) and (20.25,-36.16) .. (20.25,-41.38)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((29.61,41.78)
 -- (107.73,41.78)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.99,182.71)
 .. controls (-9.99,182.71) and (-9.27,120.44) .. (-9.63,116.12)
 .. controls (-9.99,111.80) and (0.09,55.64) .. (-0.27,53.12)
 .. controls (-0.63,50.60) and (1.17,19.64) .. (0.81,12.08)
 .. controls (0.45,4.52) and (7.29,-51.28) .. (7.29,-51.28)
 .. controls (7.29,-51.28) and (19.53,-120.40) .. (19.17,-126.52)
 .. controls (18.81,-132.64) and (19.53,-141.64) .. (19.89,-145.24)
 .. controls (20.25,-148.84) and (41.49,-195.63) .. (41.49,-195.63)
));
endfig;
beginfig(270);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char66 \char97 \char115 \char115 \char105 \char110 \mainfont{} etex,(116.55,41.78),0.0,0);
ATTR__height := -1;
drawoptions();
l_label(btex \thhugesize \thfb\char82 {}\char105 {}\char118 {}\char105 {}\accent18 \char101 {}\char114 {}\char101 {}\ \char45 {}\char49 {}\char48 {}\char48 {}\char48 {}\mainfont{} etex,((-116.55,181.28)
 .. controls (-91.20,195.63) and (-54.85,128.18) .. (-48.15,83.72)
 .. controls (-36.27,4.88) and (-49.23,-53.08) .. (-45.63,-104.20)
));
drawoptions();
p_label.llft(btex \thaltitude \thfb\char57 \char48 \char48 \mainfont{} etex,(21.15,-149.38),0.0,1);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char57 \char48 \char55 \mainfont{} etex,(4.23,-24.64),0.0,1);
endfig;
background:=(0.61750,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.61750, 0.25000, 1.00000);
current_scrap := "fromagereSP19bis@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP19bis";
beginfig(271);
draw_upscrap(1)(1,((3.23,-4.20)
 .. controls (3.85,-2.09) and (4.78,-1.03) .. (3.16,2.69)
 .. controls (1.14,7.34) and (-0.05,18.28) .. (-0.05,18.28)
),
1,((-4.73,4.60)
 .. controls (-4.73,4.60) and (-4.78,-1.18) .. (-4.73,-2.37)
));
draw_downscrap;
endfig;
beginfig(272);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.73,4.60)
 .. controls (-4.73,4.60) and (-4.78,-1.18) .. (-4.73,-2.37)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.23,-4.20)
 .. controls (3.85,-2.09) and (4.78,-1.03) .. (3.16,2.69)
 .. controls (1.14,7.34) and (-0.05,18.28) .. (-0.05,18.28)
));
endfig;
background:=(0.73750,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.73750, 0.25000, 1.00000);
current_scrap := "fromagereSP19@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP19";
beginfig(273);
ATTR__height := -1;
drawoptions();
l_rockborder(((3.55,-14.15)
 -- (3.17,-16.63)
 .. controls (3.17,-16.63) and (3.69,-21.03) .. (4.76,-21.03)
 .. controls (5.84,-21.03) and (7.12,-18.74) .. (7.12,-18.74)
 -- (7.50,-15.76)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((0.74,8.24)
 -- (-0.52,5.06)
 -- (-1.59,1.64)
 .. controls (-1.59,1.64) and (-0.74,-3.87) .. (-0.37,-4.17)
 .. controls (-0.01,-4.46) and (3.83,-7.27) .. (4.28,-6.38)
 .. controls (4.74,-5.51) and (5.12,-1.57) .. (5.31,-1.16)
 .. controls (5.50,-0.75) and (5.75,2.18) .. (5.76,2.74)
 .. controls (5.78,3.29) and (4.16,7.13) .. (4.16,7.13)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockedge(((1.66,5.77)
 -- (2.42,2.59)
 -- (2.54,-2.23)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((5.34,-28.35)
 -- (5.43,-30.66)
 -- (7.84,-30.98)
 .. controls (7.84,-30.98) and (8.74,-32.05) .. (9.10,-31.77)
 .. controls (9.46,-31.50) and (10.45,-29.35) .. (10.00,-29.00)
 .. controls (9.56,-28.65) and (8.75,-28.75) .. (8.67,-27.33)
 .. controls (8.59,-25.92) and (7.24,-26.64) .. (6.79,-26.65)
 .. controls (6.34,-26.65) and (5.34,-28.35) .. cycle
));
endfig;
beginfig(274);
draw_upscrap(1)(1,((-6.46,8.35)
 .. controls (-6.30,5.94) and (-8.33,-1.64) .. (-9.40,-4.92)
 .. controls (-10.47,-8.19) and (-9.78,-16.07) .. (-10.15,-18.19)
 .. controls (-10.53,-20.31) and (-11.47,-24.70) .. (-11.86,-28.22)
 .. controls (-12.24,-31.76) and (-11.34,-35.17) .. (-11.34,-35.17)
),
1,((13.05,-32.83)
 .. controls (13.05,-32.83) and (13.05,-30.85) .. (12.01,-24.14)
 .. controls (10.99,-17.52) and (10.99,-6.42) .. (10.39,-2.79)
 .. controls (9.85,0.53) and (9.51,2.88) .. (8.53,7.39)
));
draw_downscrap;
endfig;
beginfig(275);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((13.05,-32.83)
 .. controls (13.05,-32.83) and (13.05,-30.85) .. (12.01,-24.14)
 .. controls (10.99,-17.52) and (10.99,-6.42) .. (10.39,-2.79)
 .. controls (9.85,0.53) and (9.51,2.88) .. (8.53,7.39)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((0.67,-13.77)
 .. controls (0.67,-13.77) and (-0.82,-20.51) .. (-1.03,-27.40)
 .. controls (-1.24,-34.36) and (-0.51,-40.48) .. (-0.51,-40.48)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-6.46,8.35)
 .. controls (-6.30,5.94) and (-8.33,-1.64) .. (-9.40,-4.92)
 .. controls (-10.47,-8.19) and (-9.78,-16.07) .. (-10.15,-18.19)
 .. controls (-10.53,-20.31) and (-11.47,-24.70) .. (-11.86,-28.22)
 .. controls (-12.24,-31.76) and (-11.34,-35.17) .. (-11.34,-35.17)
));
endfig;
beginfig(276);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char57 \char49 \char51 \mainfont{} etex,(-8.39,0.54),0.0,1);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char57 \char49 \char51 \mainfont{} etex,(-13.05,-33.91),0.0,1);
endfig;
background:=(0.58750,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.58750, 0.25000, 1.00000);
current_scrap := "fromagereSP18@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP18";
beginfig(277);
ATTR__height := -1;
drawoptions();
l_pit(((-19.08,25.55)
 .. controls (-45.36,35.64) and (-48.24,8.63) .. (-47.52,5.39)
));
endfig;
beginfig(278);
draw_upscrap(1)(1,((-32.04,56.52)
 .. controls (-32.04,56.52) and (-48.60,52.56) .. (-44.64,41.04)
 .. controls (-40.68,29.52) and (-39.96,26.27) .. (-39.96,20.51)
 .. controls (-39.96,14.75) and (-36.00,10.79) .. (-33.84,8.63)
 .. controls (-31.68,6.47) and (-24.48,1.43) .. (-22.68,-1.09)
 .. controls (-20.88,-3.61) and (-12.96,-9.73) .. (-10.80,-11.89)
 .. controls (-8.64,-14.05) and (-4.68,-20.17) .. (-1.80,-23.05)
 .. controls (1.08,-25.93) and (7.56,-27.73) .. (9.36,-29.89)
 .. controls (11.16,-32.05) and (14.76,-34.93) .. (15.12,-36.37)
 .. controls (15.48,-37.81) and (19.08,-46.80) .. (19.07,-48.60)
 .. controls (19.07,-50.40) and (20.15,-56.52) .. (20.15,-56.52)
),
1,((24.83,-42.84)
 .. controls (24.48,-35.29) and (16.56,-28.09) .. (15.12,-27.37)
 .. controls (13.68,-26.65) and (8.28,-19.45) .. (6.84,-17.65)
 .. controls (5.40,-15.85) and (-2.52,-8.29) .. (-3.24,-5.41)
 .. controls (-3.96,-2.53) and (-12.96,1.07) .. (-15.84,3.59)
 .. controls (-18.72,6.11) and (-24.84,7.91) .. (-26.64,12.23)
 .. controls (-28.44,16.55) and (-33.48,22.67) .. (-33.48,26.63)
 .. controls (-33.48,30.60) and (-33.48,36.36) .. (-34.92,43.20)
 .. controls (-36.36,50.04) and (-23.04,54.36) .. (-23.04,54.36)
));
draw_downscrap;
endfig;
beginfig(279);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((24.83,-42.84)
 .. controls (24.48,-35.29) and (16.56,-28.09) .. (15.12,-27.37)
 .. controls (13.68,-26.65) and (8.28,-19.45) .. (6.84,-17.65)
 .. controls (5.40,-15.85) and (-2.52,-8.29) .. (-3.24,-5.41)
 .. controls (-3.96,-2.53) and (-12.96,1.07) .. (-15.84,3.59)
 .. controls (-18.72,6.11) and (-24.84,7.91) .. (-26.64,12.23)
 .. controls (-28.44,16.55) and (-33.48,22.67) .. (-33.48,26.63)
 .. controls (-33.48,30.60) and (-33.48,36.36) .. (-34.92,43.20)
 .. controls (-36.36,50.04) and (-23.04,54.36) .. (-23.04,54.36)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-32.04,56.52)
 .. controls (-32.04,56.52) and (-48.60,52.56) .. (-44.64,41.04)
 .. controls (-40.68,29.52) and (-39.96,26.27) .. (-39.96,20.51)
 .. controls (-39.96,14.75) and (-36.00,10.79) .. (-33.84,8.63)
 .. controls (-31.68,6.47) and (-24.48,1.43) .. (-22.68,-1.09)
 .. controls (-20.88,-3.61) and (-12.96,-9.73) .. (-10.80,-11.89)
 .. controls (-8.64,-14.05) and (-4.68,-20.17) .. (-1.80,-23.05)
 .. controls (1.08,-25.93) and (7.56,-27.73) .. (9.36,-29.89)
 .. controls (11.16,-32.05) and (14.76,-34.93) .. (15.12,-36.37)
 .. controls (15.48,-37.81) and (19.08,-46.80) .. (19.07,-48.60)
 .. controls (19.07,-50.40) and (20.15,-56.52) .. (20.15,-56.52)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-27.36,40.32)
 -- (32.77,40.31)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-29.52,54.54)
 .. controls (-29.52,54.54) and (-42.48,50.22) .. (-39.24,38.88)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-26.28,20.51)
 -- (33.12,20.51)
));
endfig;
beginfig(280);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char57 \char52 \char55 \mainfont{} etex,(20.52,-32.77),0.0,1);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char67 \char97 \char115 \char99 \char97 \char100 \char101 \mainfont{} etex,(48.25,40.31),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char55 \mainfont{} etex,(48.60,20.87),0.0,0);
endfig;
background:=(0.55000,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.55000, 0.25000, 1.00000);
current_scrap := "fromagereSP17@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP17";
beginfig(281);
draw_upscrap(1)(1,((-12.60,43.38)
 .. controls (-12.60,43.38) and (-17.28,37.62) .. (-19.08,35.10)
 .. controls (-20.88,32.58) and (-29.17,32.22) .. (-25.56,26.82)
 .. controls (-21.96,21.42) and (-16.92,18.54) .. (-16.92,18.54)
 .. controls (-16.92,18.54) and (-12.96,12.77) .. (-9.00,9.89)
 .. controls (-5.04,7.01) and (3.61,1.25) .. (5.05,-2.35)
 .. controls (6.49,-5.95) and (9.01,-10.99) .. (9.37,-13.51)
 .. controls (9.73,-16.02) and (14.41,-23.58) .. (14.41,-23.58)
 -- (15.85,-28.62)
 .. controls (15.85,-28.62) and (16.57,-33.30) .. (13.33,-35.46)
 .. controls (10.09,-37.62) and (5.05,-41.22) .. (5.05,-41.22)
),
1,((14.05,-43.38)
 .. controls (14.05,-43.38) and (20.53,-39.78) .. (24.85,-36.90)
 .. controls (29.17,-34.02) and (20.89,-25.02) .. (20.17,-22.50)
 .. controls (19.45,-19.98) and (17.65,-16.02) .. (15.85,-7.39)
 .. controls (14.05,1.25) and (1.45,11.69) .. (1.45,11.69)
 .. controls (1.45,11.69) and (-5.76,19.61) .. (-7.20,19.97)
 .. controls (-8.64,20.33) and (-14.04,19.62) .. (-17.28,27.90)
 .. controls (-18.81,31.81) and (-8.28,39.78) .. (-8.28,39.78)
));
draw_downscrap;
endfig;
beginfig(282);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((14.05,-43.38)
 .. controls (14.05,-43.38) and (20.53,-39.78) .. (24.85,-36.90)
 .. controls (29.17,-34.02) and (20.89,-25.02) .. (20.17,-22.50)
 .. controls (19.45,-19.98) and (17.65,-16.02) .. (15.85,-7.39)
 .. controls (14.05,1.25) and (1.45,11.69) .. (1.45,11.69)
 .. controls (1.45,11.69) and (-5.76,19.61) .. (-7.20,19.97)
 .. controls (-8.64,20.33) and (-14.04,19.62) .. (-17.28,27.90)
 .. controls (-18.81,31.81) and (-8.28,39.78) .. (-8.28,39.78)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-18.54,33.48)
 .. controls (-18.54,33.48) and (-23.40,29.88) .. (-19.80,25.20)
 .. controls (-16.20,20.52) and (-8.82,16.55) .. (-7.74,14.93)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-12.60,43.38)
 .. controls (-12.60,43.38) and (-17.28,37.62) .. (-19.08,35.10)
 .. controls (-20.88,32.58) and (-29.17,32.22) .. (-25.56,26.82)
 .. controls (-21.96,21.42) and (-16.92,18.54) .. (-16.92,18.54)
 .. controls (-16.92,18.54) and (-12.96,12.77) .. (-9.00,9.89)
 .. controls (-5.04,7.01) and (3.61,1.25) .. (5.05,-2.35)
 .. controls (6.49,-5.95) and (9.01,-10.99) .. (9.37,-13.51)
 .. controls (9.73,-16.02) and (14.41,-23.58) .. (14.41,-23.58)
 -- (15.85,-28.62)
 .. controls (15.85,-28.62) and (16.57,-33.30) .. (13.33,-35.46)
 .. controls (10.09,-37.62) and (5.05,-41.22) .. (5.05,-41.22)
));
endfig;
beginfig(283);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char57 \char53 \char53 \mainfont{} etex,(11.53,1.25),0.0,1);
endfig;
background:=(0.50500,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.50500, 0.25000, 1.00000);
current_scrap := "fromagereSP16@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP16";
beginfig(284);
draw_upscrap(1)(1,((-42.30,-45.00)
 .. controls (-42.30,-45.00) and (-35.82,-40.32) .. (-36.18,-36.72)
 .. controls (-36.54,-33.12) and (-37.98,-28.08) .. (-38.70,-24.11)
 .. controls (-39.42,-20.15) and (-40.14,-10.79) .. (-40.14,-10.79)
 .. controls (-40.14,-10.79) and (-41.22,-8.99) .. (-39.78,-4.31)
 .. controls (-38.34,0.37) and (-39.06,1.81) .. (-35.46,6.84)
 .. controls (-31.86,11.88) and (-29.34,16.56) .. (-31.86,22.32)
 .. controls (-34.38,28.08) and (-35.46,32.76) .. (-35.82,35.27)
 .. controls (-36.18,37.79) and (-40.14,45.00) .. (-40.14,45.00)
),
1,((-43.02,35.64)
 -- (-39.06,25.56)
 .. controls (-39.06,25.56) and (-37.26,18.00) .. (-39.42,13.32)
 .. controls (-41.58,8.64) and (-43.74,1.81) .. (-43.74,1.81)
 .. controls (-43.74,1.81) and (-48.42,-8.27) .. (-48.06,-10.43)
 .. controls (-47.70,-12.59) and (-45.90,-22.31) .. (-45.54,-25.91)
 .. controls (-45.18,-29.51) and (-42.30,-36.72) .. (-46.63,-41.39)
));
draw_downscrap;
endfig;
beginfig(285);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-43.02,35.64)
 -- (-39.06,25.56)
 .. controls (-39.06,25.56) and (-37.26,18.00) .. (-39.42,13.32)
 .. controls (-41.58,8.64) and (-43.74,1.81) .. (-43.74,1.81)
 .. controls (-43.74,1.81) and (-48.42,-8.27) .. (-48.06,-10.43)
 .. controls (-47.70,-12.59) and (-45.90,-22.31) .. (-45.54,-25.91)
 .. controls (-45.18,-29.51) and (-42.30,-36.72) .. (-46.63,-41.39)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-42.30,-45.00)
 .. controls (-42.30,-45.00) and (-35.82,-40.32) .. (-36.18,-36.72)
 .. controls (-36.54,-33.12) and (-37.98,-28.08) .. (-38.70,-24.11)
 .. controls (-39.42,-20.15) and (-40.14,-10.79) .. (-40.14,-10.79)
 .. controls (-40.14,-10.79) and (-41.22,-8.99) .. (-39.78,-4.31)
 .. controls (-38.34,0.37) and (-39.06,1.81) .. (-35.46,6.84)
 .. controls (-31.86,11.88) and (-29.34,16.56) .. (-31.86,22.32)
 .. controls (-34.38,28.08) and (-35.46,32.76) .. (-35.82,35.27)
 .. controls (-36.18,37.79) and (-40.14,45.00) .. (-40.14,45.00)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-29.70,-37.08)
 -- (35.82,-37.08)
));
endfig;
beginfig(286);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char67 \char97 \char115 \char99 \char97 \char100 \char101 \mainfont{} etex,(48.42,-37.08),0.0,0);
endfig;
background:=(0.44500,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.44500, 0.25000, 1.00000);
current_scrap := "fromagereSP15@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP15";
beginfig(287);
draw_upscrap(1)(1,((-34.92,59.04)
 .. controls (-34.92,59.04) and (-46.79,49.32) .. (-43.55,41.76)
 .. controls (-40.31,34.21) and (-39.23,28.45) .. (-38.87,26.29)
 .. controls (-38.51,24.13) and (-36.38,16.94) .. (-40.31,9.73)
 .. controls (-44.63,1.81) and (-46.07,-10.79) .. (-46.07,-10.79)
 .. controls (-46.07,-10.79) and (-51.47,-19.44) .. (-52.91,-23.76)
 .. controls (-54.35,-28.08) and (-61.19,-41.76) .. (-58.31,-48.96)
 .. controls (-55.43,-56.16) and (-54.71,-59.04) .. (-54.71,-59.04)
),
1,((-51.83,-49.68)
 .. controls (-54.71,-38.16) and (-51.83,-37.08) .. (-51.83,-37.08)
 .. controls (-51.83,-37.08) and (-44.27,-19.44) .. (-43.19,-15.84)
 .. controls (-42.11,-12.23) and (-37.43,2.89) .. (-32.39,9.37)
 .. controls (-27.35,15.85) and (-34.55,33.85) .. (-34.55,33.85)
 .. controls (-34.55,33.85) and (-35.28,43.92) .. (-36.00,46.80)
 .. controls (-36.72,49.68) and (-29.88,53.28) .. (-29.88,53.28)
));
draw_downscrap;
endfig;
beginfig(288);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-51.83,-49.68)
 .. controls (-54.71,-38.16) and (-51.83,-37.08) .. (-51.83,-37.08)
 .. controls (-51.83,-37.08) and (-44.27,-19.44) .. (-43.19,-15.84)
 .. controls (-42.11,-12.23) and (-37.43,2.89) .. (-32.39,9.37)
 .. controls (-27.35,15.85) and (-34.55,33.85) .. (-34.55,33.85)
 .. controls (-34.55,33.85) and (-35.28,43.92) .. (-36.00,46.80)
 .. controls (-36.72,49.68) and (-29.88,53.28) .. (-29.88,53.28)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-37.43,32.41)
 .. controls (-37.43,32.41) and (-33.29,22.33) .. (-34.55,16.57)
 .. controls (-35.81,10.81) and (-37.79,7.75) .. (-38.51,6.13)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-34.92,59.04)
 .. controls (-34.92,59.04) and (-46.79,49.32) .. (-43.55,41.76)
 .. controls (-40.31,34.21) and (-39.23,28.45) .. (-38.87,26.29)
 .. controls (-38.51,24.13) and (-36.38,16.94) .. (-40.31,9.73)
 .. controls (-44.63,1.81) and (-46.07,-10.79) .. (-46.07,-10.79)
 .. controls (-46.07,-10.79) and (-51.47,-19.44) .. (-52.91,-23.76)
 .. controls (-54.35,-28.08) and (-61.19,-41.76) .. (-58.31,-48.96)
 .. controls (-55.43,-56.16) and (-54.71,-59.04) .. (-54.71,-59.04)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-28.44,35.29)
 -- (50.40,35.30)
));
endfig;
beginfig(289);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char57 \char54 \char54 \mainfont{} etex,(-58.49,-39.42),0.0,1);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char68 \char111 \char117 \char99 \char104 \char101 \mainfont{} etex,(61.19,34.94),0.0,0);
endfig;
background:=(0.38500,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.38500, 0.25000, 1.00000);
current_scrap := "fromagereSP14@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP14";
beginfig(290);
draw_upscrap(1)(1,((4.50,62.46)
 -- (3.78,45.18)
 .. controls (3.78,45.18) and (7.38,28.26) .. (1.98,23.22)
 .. controls (-3.42,18.19) and (-8.10,10.27) .. (-7.02,3.43)
 .. controls (-5.94,-3.41) and (-7.74,-22.49) .. (-7.74,-22.49)
 .. controls (-7.74,-22.49) and (-8.10,-35.09) .. (-8.82,-37.25)
 .. controls (-9.54,-39.41) and (-4.50,-51.29) .. (-10.98,-56.70)
),
1,((-5.94,-62.46)
 .. controls (-4.50,-62.10) and (-1.26,-47.33) .. (-1.26,-44.45)
 .. controls (-1.26,-41.57) and (-0.90,-31.49) .. (-1.98,-27.89)
 .. controls (-3.06,-24.29) and (-1.62,-5.57) .. (-1.62,-2.69)
 .. controls (-1.62,0.19) and (0.54,9.19) .. (1.98,13.15)
 .. controls (3.42,17.10) and (10.62,23.22) .. (10.62,23.22)
 .. controls (10.62,23.22) and (10.98,38.33) .. (10.98,41.22)
 .. controls (10.98,44.10) and (10.98,56.34) .. (10.98,56.34)
));
draw_downscrap;
endfig;
beginfig(291);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-5.94,-62.46)
 .. controls (-4.50,-62.10) and (-1.26,-47.33) .. (-1.26,-44.45)
 .. controls (-1.26,-41.57) and (-0.90,-31.49) .. (-1.98,-27.89)
 .. controls (-3.06,-24.29) and (-1.62,-5.57) .. (-1.62,-2.69)
 .. controls (-1.62,0.19) and (0.54,9.19) .. (1.98,13.15)
 .. controls (3.42,17.10) and (10.62,23.22) .. (10.62,23.22)
 .. controls (10.62,23.22) and (10.98,38.33) .. (10.98,41.22)
 .. controls (10.98,44.10) and (10.98,56.34) .. (10.98,56.34)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((7.92,38.70)
 .. controls (7.92,38.70) and (9.36,26.82) .. (3.60,21.06)
 .. controls (-2.16,15.31) and (-2.70,11.53) .. (-3.06,7.57)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.50,62.46)
 -- (3.78,45.18)
 .. controls (3.78,45.18) and (7.38,28.26) .. (1.98,23.22)
 .. controls (-3.42,18.19) and (-8.10,10.27) .. (-7.02,3.43)
 .. controls (-5.94,-3.41) and (-7.74,-22.49) .. (-7.74,-22.49)
 .. controls (-7.74,-22.49) and (-8.10,-35.09) .. (-8.82,-37.25)
 .. controls (-9.54,-39.41) and (-4.50,-51.29) .. (-10.98,-56.70)
));
endfig;
background:=(0.32500,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.32500, 0.25000, 1.00000);
current_scrap := "fromagereSP13@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP13";
beginfig(292);
draw_upscrap(1)(1,((11.70,-56.16)
 .. controls (11.70,-56.16) and (10.26,-47.88) .. (10.98,-43.56)
 .. controls (11.70,-39.23) and (12.06,-35.27) .. (9.18,-29.51)
 .. controls (6.30,-23.75) and (-0.54,-22.67) .. (-0.90,-19.79)
 .. controls (-1.26,-16.91) and (-5.22,-15.11) .. (-2.34,-5.75)
 .. controls (0.54,3.61) and (4.85,12.97) .. (5.21,15.85)
 .. controls (5.57,18.73) and (10.25,27.01) .. (9.17,34.57)
 .. controls (8.09,42.13) and (5.21,56.16) .. (5.21,56.16)
),
1,((-3.79,54.72)
 .. controls (-3.79,54.72) and (-0.91,44.64) .. (-0.91,42.84)
 .. controls (-0.91,41.04) and (0.53,33.49) .. (-0.91,29.89)
 .. controls (-2.35,26.29) and (-2.71,18.73) .. (-3.43,15.85)
 .. controls (-4.15,12.97) and (-5.94,-1.07) .. (-6.30,-2.51)
 .. controls (-6.66,-3.95) and (-12.06,-16.55) .. (-7.02,-21.23)
 .. controls (-1.98,-25.91) and (1.26,-31.31) .. (1.26,-31.31)
 .. controls (1.26,-31.31) and (4.86,-42.48) .. (5.23,-50.04)
));
draw_downscrap;
endfig;
beginfig(293);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.79,54.72)
 .. controls (-3.79,54.72) and (-0.91,44.64) .. (-0.91,42.84)
 .. controls (-0.91,41.04) and (0.53,33.49) .. (-0.91,29.89)
 .. controls (-2.35,26.29) and (-2.71,18.73) .. (-3.43,15.85)
 .. controls (-4.15,12.97) and (-5.94,-1.07) .. (-6.30,-2.51)
 .. controls (-6.66,-3.95) and (-12.06,-16.55) .. (-7.02,-21.23)
 .. controls (-1.98,-25.91) and (1.26,-31.31) .. (1.26,-31.31)
 .. controls (1.26,-31.31) and (4.86,-42.48) .. (5.23,-50.04)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.70,-56.16)
 .. controls (11.70,-56.16) and (10.26,-47.88) .. (10.98,-43.56)
 .. controls (11.70,-39.23) and (12.06,-35.27) .. (9.18,-29.51)
 .. controls (6.30,-23.75) and (-0.54,-22.67) .. (-0.90,-19.79)
 .. controls (-1.26,-16.91) and (-5.22,-15.11) .. (-2.34,-5.75)
 .. controls (0.54,3.61) and (4.85,12.97) .. (5.21,15.85)
 .. controls (5.57,18.73) and (10.25,27.01) .. (9.17,34.57)
 .. controls (8.09,42.13) and (5.21,56.16) .. (5.21,56.16)
));
endfig;
beginfig(294);
drawoptions();
p_label.rt(btex \thaltitude \thfb\char57 \char56 \char52 \mainfont{} etex,(11.34,-33.65),0.0,1);
endfig;
background:=(0.25750,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.25750, 0.25000, 1.00000);
current_scrap := "fromagereSP12@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP12";
beginfig(295);
draw_upscrap(1)(1,((-74.71,-104.05)
 .. controls (-74.71,-104.05) and (-79.75,-92.17) .. (-78.31,-88.21)
 .. controls (-76.87,-84.25) and (-68.95,-82.09) .. (-67.51,-80.65)
 .. controls (-66.07,-79.21) and (-48.06,-66.25) .. (-48.06,-66.25)
 .. controls (-48.06,-66.25) and (-40.50,-66.24) .. (-40.50,-55.80)
 .. controls (-40.50,-45.36) and (-39.42,-35.64) .. (-39.42,-31.33)
 .. controls (-39.42,-27.01) and (-39.78,-24.85) .. (-39.06,-16.57)
 .. controls (-38.34,-8.29) and (-37.98,8.28) .. (-42.66,7.92)
 .. controls (-47.34,7.55) and (-52.38,7.55) .. (-52.38,7.55)
),
1,((-53.10,2.15)
 .. controls (-53.10,2.15) and (-45.90,1.43) .. (-45.54,-3.61)
 .. controls (-45.18,-8.65) and (-44.82,-13.69) .. (-44.82,-13.69)
 .. controls (-44.82,-13.69) and (-45.90,-29.17) .. (-45.90,-32.40)
 .. controls (-45.90,-35.64) and (-46.26,-46.44) .. (-46.62,-47.88)
 .. controls (-46.98,-49.32) and (-42.66,-54.72) .. (-52.39,-62.64)
 .. controls (-62.11,-70.57) and (-79.75,-78.49) .. (-79.75,-78.49)
 .. controls (-79.75,-78.49) and (-88.03,-81.01) .. (-86.95,-88.94)
 .. controls (-85.88,-96.85) and (-83.72,-105.49) .. (-83.72,-105.49)
));
draw_downscrap;
endfig;
beginfig(296);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-53.10,2.15)
 .. controls (-53.10,2.15) and (-45.90,1.43) .. (-45.54,-3.61)
 .. controls (-45.18,-8.65) and (-44.82,-13.69) .. (-44.82,-13.69)
 .. controls (-44.82,-13.69) and (-45.90,-29.17) .. (-45.90,-32.40)
 .. controls (-45.90,-35.64) and (-46.26,-46.44) .. (-46.62,-47.88)
 .. controls (-46.98,-49.32) and (-42.66,-54.72) .. (-52.39,-62.64)
 .. controls (-62.11,-70.57) and (-79.75,-78.49) .. (-79.75,-78.49)
 .. controls (-79.75,-78.49) and (-88.03,-81.01) .. (-86.95,-88.94)
 .. controls (-85.88,-96.85) and (-83.72,-105.49) .. (-83.72,-105.49)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-74.71,-104.05)
 .. controls (-74.71,-104.05) and (-79.75,-92.17) .. (-78.31,-88.21)
 .. controls (-76.87,-84.25) and (-68.95,-82.09) .. (-67.51,-80.65)
 .. controls (-66.07,-79.21) and (-48.06,-66.25) .. (-48.06,-66.25)
 .. controls (-48.06,-66.25) and (-40.50,-66.24) .. (-40.50,-55.80)
 .. controls (-40.50,-45.36) and (-39.42,-35.64) .. (-39.42,-31.33)
 .. controls (-39.42,-27.01) and (-39.78,-24.85) .. (-39.06,-16.57)
 .. controls (-38.34,-8.29) and (-37.98,8.28) .. (-42.66,7.92)
 .. controls (-47.34,7.55) and (-52.38,7.55) .. (-52.38,7.55)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-68.23,-76.33)
 .. controls (-68.23,-76.33) and (-75.97,-81.37) .. (-77.59,-82.27)
 .. controls (-79.21,-83.17) and (-84.07,-85.51) .. (-81.91,-94.87)
));
endfig;
beginfig(297);
ATTR__height := -1;
drawoptions();
l_label(btex \thhugesize \thfb\char82 {}\char105 {}\char118 {}\char105 {}\accent18 \char101 {}\char114 {}\char101 {}\ \char100 {}\char101 {}\ \char108 {}\char97 {}\ \char102 {}\char114 {}\char111 {}\char109 {}\char97 {}\char103 {}\accent18 \char101 {}\char114 {}\char101 {}\mainfont{} etex,((49.50,227.18)
 .. controls (49.50,227.18) and (52.38,124.93) .. (64.98,78.85)
 .. controls (78.54,29.29) and (88.03,-9.35) .. (78.32,-69.84)
 .. controls (70.17,-120.58) and (70.40,-154.45) .. (87.32,-227.18)
));
endfig;
background:=(0.25000,0.29500,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.29500, 1.00000);
current_scrap := "fromagereSP11@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP11";
beginfig(298);
draw_upscrap(1)(1,((-19.09,51.84)
 .. controls (-19.09,51.84) and (-18.73,47.16) .. (-18.73,44.28)
 .. controls (-18.73,41.40) and (-17.64,28.80) .. (-17.64,28.80)
 .. controls (-17.64,28.80) and (-18.36,20.52) .. (-18.36,16.92)
 .. controls (-18.36,13.32) and (-19.44,0.01) .. (-19.44,0.01)
 .. controls (-19.44,0.01) and (-20.88,-13.31) .. (-15.12,-16.19)
 .. controls (-9.36,-19.07) and (-1.08,-21.23) .. (-1.08,-21.23)
 .. controls (-1.08,-21.23) and (5.40,-25.19) .. (7.20,-25.19)
 .. controls (9.00,-25.19) and (11.16,-26.27) .. (10.08,-32.04)
 .. controls (9.00,-37.80) and (5.76,-46.09) .. (10.80,-48.96)
 .. controls (15.84,-51.84) and (20.16,-51.48) .. (20.16,-51.48)
),
1,((20.88,-46.08)
 .. controls (20.88,-46.08) and (14.04,-44.28) .. (14.04,-41.76)
 .. controls (14.04,-39.24) and (14.40,-36.72) .. (15.48,-34.56)
 .. controls (16.56,-32.40) and (18.36,-29.15) .. (18.36,-26.99)
 .. controls (18.36,-24.83) and (15.48,-17.63) .. (11.16,-16.91)
 .. controls (6.84,-16.19) and (3.96,-16.19) .. (1.80,-15.83)
 .. controls (-0.36,-15.47) and (-8.64,-12.59) .. (-8.64,-12.59)
 .. controls (-8.64,-12.59) and (-12.96,-8.63) .. (-12.96,-2.87)
 .. controls (-12.96,2.89) and (-14.04,12.60) .. (-13.32,15.12)
 .. controls (-12.60,17.64) and (-11.16,24.84) .. (-11.16,26.64)
 .. controls (-11.16,28.44) and (-11.53,35.64) .. (-11.53,35.64)
 -- (-12.61,50.04)
));
draw_downscrap;
endfig;
beginfig(299);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((20.88,-46.08)
 .. controls (20.88,-46.08) and (14.04,-44.28) .. (14.04,-41.76)
 .. controls (14.04,-39.24) and (14.40,-36.72) .. (15.48,-34.56)
 .. controls (16.56,-32.40) and (18.36,-29.15) .. (18.36,-26.99)
 .. controls (18.36,-24.83) and (15.48,-17.63) .. (11.16,-16.91)
 .. controls (6.84,-16.19) and (3.96,-16.19) .. (1.80,-15.83)
 .. controls (-0.36,-15.47) and (-8.64,-12.59) .. (-8.64,-12.59)
 .. controls (-8.64,-12.59) and (-12.96,-8.63) .. (-12.96,-2.87)
 .. controls (-12.96,2.89) and (-14.04,12.60) .. (-13.32,15.12)
 .. controls (-12.60,17.64) and (-11.16,24.84) .. (-11.16,26.64)
 .. controls (-11.16,28.44) and (-11.53,35.64) .. (-11.53,35.64)
 -- (-12.61,50.04)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((3.06,-19.25)
 .. controls (3.06,-19.25) and (9.36,-20.87) .. (10.44,-21.59)
 .. controls (11.52,-22.31) and (17.28,-25.01) .. (14.04,-31.14)
 .. controls (10.80,-37.26) and (10.62,-39.24) .. (11.16,-41.40)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-19.09,51.84)
 .. controls (-19.09,51.84) and (-18.73,47.16) .. (-18.73,44.28)
 .. controls (-18.73,41.40) and (-17.64,28.80) .. (-17.64,28.80)
 .. controls (-17.64,28.80) and (-18.36,20.52) .. (-18.36,16.92)
 .. controls (-18.36,13.32) and (-19.44,0.01) .. (-19.44,0.01)
 .. controls (-19.44,0.01) and (-20.88,-13.31) .. (-15.12,-16.19)
 .. controls (-9.36,-19.07) and (-1.08,-21.23) .. (-1.08,-21.23)
 .. controls (-1.08,-21.23) and (5.40,-25.19) .. (7.20,-25.19)
 .. controls (9.00,-25.19) and (11.16,-26.27) .. (10.08,-32.04)
 .. controls (9.00,-37.80) and (5.76,-46.09) .. (10.80,-48.96)
 .. controls (15.84,-51.84) and (20.16,-51.48) .. (20.16,-51.48)
));
endfig;
background:=(0.25000,0.36250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.36250, 1.00000);
current_scrap := "fromagereSP10@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP10";
beginfig(300);
draw_upscrap(1)(1,((13.49,-45.71)
 .. controls (13.49,-45.71) and (14.58,-35.63) .. (15.30,-32.03)
 .. controls (16.02,-28.44) and (14.94,-23.40) .. (14.94,-19.08)
 .. controls (14.94,-14.76) and (9.54,-9.71) .. (9.54,-9.71)
 .. controls (9.54,-9.71) and (1.26,1.09) .. (0.54,3.61)
 .. controls (-0.18,6.13) and (-3.06,10.45) .. (-3.78,12.61)
 .. controls (-4.50,14.77) and (-3.78,16.21) .. (-3.78,19.09)
 .. controls (-3.78,21.97) and (-3.78,23.05) .. (0.54,27.00)
 .. controls (4.86,30.96) and (0.90,37.44) .. (0.90,37.44)
 -- (0.55,51.47)
 -- (-0.89,65.51)
),
1,((-8.80,63.71)
 -- (-7.37,48.24)
 .. controls (-7.37,48.24) and (-4.50,40.68) .. (-6.66,35.64)
 .. controls (-8.82,30.60) and (-5.94,25.93) .. (-9.18,23.77)
 .. controls (-12.42,21.61) and (-16.02,16.21) .. (-14.94,12.25)
 .. controls (-13.86,8.29) and (-9.18,1.81) .. (-9.18,1.81)
 .. controls (-9.18,1.81) and (-4.14,-5.39) .. (-2.34,-8.27)
 .. controls (-0.54,-11.15) and (3.42,-14.75) .. (3.78,-16.55)
 .. controls (4.14,-18.36) and (5.94,-21.96) .. (5.94,-26.64)
 .. controls (5.94,-31.31) and (6.65,-41.75) .. (7.01,-43.91)
));
draw_downscrap;
endfig;
beginfig(301);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-8.80,63.71)
 -- (-7.37,48.24)
 .. controls (-7.37,48.24) and (-4.50,40.68) .. (-6.66,35.64)
 .. controls (-8.82,30.60) and (-5.94,25.93) .. (-9.18,23.77)
 .. controls (-12.42,21.61) and (-16.02,16.21) .. (-14.94,12.25)
 .. controls (-13.86,8.29) and (-9.18,1.81) .. (-9.18,1.81)
 .. controls (-9.18,1.81) and (-4.14,-5.39) .. (-2.34,-8.27)
 .. controls (-0.54,-11.15) and (3.42,-14.75) .. (3.78,-16.55)
 .. controls (4.14,-18.36) and (5.94,-21.96) .. (5.94,-26.64)
 .. controls (5.94,-31.31) and (6.65,-41.75) .. (7.01,-43.91)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((13.49,-45.71)
 .. controls (13.49,-45.71) and (14.58,-35.63) .. (15.30,-32.03)
 .. controls (16.02,-28.44) and (14.94,-23.40) .. (14.94,-19.08)
 .. controls (14.94,-14.76) and (9.54,-9.71) .. (9.54,-9.71)
 .. controls (9.54,-9.71) and (1.26,1.09) .. (0.54,3.61)
 .. controls (-0.18,6.13) and (-3.06,10.45) .. (-3.78,12.61)
 .. controls (-4.50,14.77) and (-3.78,16.21) .. (-3.78,19.09)
 .. controls (-3.78,21.97) and (-3.78,23.05) .. (0.54,27.00)
 .. controls (4.86,30.96) and (0.90,37.44) .. (0.90,37.44)
 -- (0.55,51.47)
 -- (-0.89,65.51)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((11.34,-30.59)
 .. controls (11.34,-30.59) and (10.43,-47.15) .. (10.61,-51.83)
 .. controls (10.79,-56.51) and (11.51,-62.81) .. (11.51,-65.51)
));
endfig;
beginfig(302);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char49 \char48 \char49 \char49 \mainfont{} etex,(12.78,-13.50),0.0,1);
endfig;
background:=(0.25000,0.43750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.43750, 1.00000);
current_scrap := "fromagereSP9@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP9";
beginfig(303);
draw_upscrap(1)(1,((2.18,-67.86)
 -- (0.74,-50.94)
 -- (-1.43,-40.86)
 .. controls (-1.43,-40.86) and (-0.35,-31.49) .. (1.81,-31.13)
 .. controls (3.97,-30.77) and (9.01,-28.97) .. (9.01,-26.81)
 .. controls (9.01,-24.64) and (10.44,-15.28) .. (10.80,-12.40)
 .. controls (11.16,-9.52) and (10.80,16.03) .. (10.80,17.83)
 .. controls (10.80,19.63) and (14.04,36.55) .. (14.40,37.99)
 .. controls (14.76,39.43) and (13.32,52.02) .. (13.32,52.02)
 .. controls (13.32,52.02) and (10.08,61.02) .. (9.00,63.18)
 .. controls (7.93,65.34) and (1.09,69.66) .. (1.09,69.66)
),
1,((-4.31,56.34)
 .. controls (-4.31,56.34) and (-2.87,53.83) .. (-5.03,50.23)
 .. controls (-7.20,46.63) and (-6.84,43.03) .. (-7.56,41.59)
 .. controls (-8.28,40.15) and (-9.00,33.67) .. (-9.72,32.23)
 .. controls (-10.44,30.79) and (-11.16,28.99) .. (-11.16,21.43)
 .. controls (-11.16,13.87) and (-11.53,-1.61) .. (-11.89,-5.21)
 .. controls (-12.25,-8.81) and (-13.33,-15.65) .. (-13.33,-15.65)
 -- (-14.76,-26.10)
),
1,((-14.76,-26.10)
 .. controls (-12.56,-30.25) and (-8.63,-33.66) .. (-8.27,-38.34)
 .. controls (-7.91,-43.02) and (-8.27,-51.31) .. (-7.91,-53.47)
 .. controls (-7.54,-55.63) and (-5.74,-67.86) .. (-5.74,-69.66)
));
draw_downscrap;
endfig;
beginfig(304);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.31,56.34)
 .. controls (-4.31,56.34) and (-2.87,53.83) .. (-5.03,50.23)
 .. controls (-7.20,46.63) and (-6.84,43.03) .. (-7.56,41.59)
 .. controls (-8.28,40.15) and (-9.00,33.67) .. (-9.72,32.23)
 .. controls (-10.44,30.79) and (-11.16,28.99) .. (-11.16,21.43)
 .. controls (-11.16,13.87) and (-11.53,-1.61) .. (-11.89,-5.21)
 .. controls (-12.25,-8.81) and (-13.33,-15.65) .. (-13.33,-15.65)
 -- (-14.76,-26.10)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2.18,-67.86)
 -- (0.74,-50.94)
 -- (-1.43,-40.86)
 .. controls (-1.43,-40.86) and (-0.35,-31.49) .. (1.81,-31.13)
 .. controls (3.97,-30.77) and (9.01,-28.97) .. (9.01,-26.81)
 .. controls (9.01,-24.64) and (10.44,-15.28) .. (10.80,-12.40)
 .. controls (11.16,-9.52) and (10.80,16.03) .. (10.80,17.83)
 .. controls (10.80,19.63) and (14.04,36.55) .. (14.40,37.99)
 .. controls (14.76,39.43) and (13.32,52.02) .. (13.32,52.02)
 .. controls (13.32,52.02) and (10.08,61.02) .. (9.00,63.18)
 .. controls (7.93,65.34) and (1.09,69.66) .. (1.09,69.66)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-14.76,-26.10)
 .. controls (-12.56,-30.25) and (-8.63,-33.66) .. (-8.27,-38.34)
 .. controls (-7.91,-43.02) and (-8.27,-51.31) .. (-7.91,-53.47)
 .. controls (-7.54,-55.63) and (-5.74,-67.86) .. (-5.74,-69.66)
));
endfig;
beginfig(305);
drawoptions();
p_label.rt(btex \thaltitude \thfb\char49 \char48 \char51 \char48 \mainfont{} etex,(14.04,46.98),0.0,1);
endfig;
background:=(0.25000,0.52000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.52000, 1.00000);
current_scrap := "fromagereSP8@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP8";
beginfig(306);
ATTR__height := -1;
drawoptions();
l_pit(((3.78,44.20)
 .. controls (3.42,46.00) and (1.62,50.68) .. (1.62,50.68)
 -- (-8.10,57.16)
 .. controls (-8.10,57.16) and (-14.22,58.96) .. (-16.02,50.68)
 .. controls (-17.82,42.40) and (-9.18,40.24) .. (-6.30,37.72)
));
ATTR__height := -1;
drawoptions();
l_pit(((-2.70,-32.85)
 .. controls (-2.70,-32.85) and (-7.02,-30.69) .. (-8.10,-28.17)
 .. controls (-9.18,-25.65) and (-13.86,-24.21) .. (-13.86,-24.21)
 .. controls (-13.86,-24.21) and (-16.38,-25.65) .. (-19.62,-29.25)
 .. controls (-22.86,-32.86) and (-15.30,-38.98) .. (-15.30,-38.98)
));
endfig;
beginfig(307);
draw_upscrap(1)(1,((-4.86,62.20)
 .. controls (-4.86,62.20) and (-4.86,58.24) .. (-0.54,56.08)
 .. controls (3.78,53.92) and (4.86,52.84) .. (5.94,50.32)
 .. controls (7.02,47.80) and (8.10,42.40) .. (9.18,40.24)
 .. controls (10.26,38.08) and (14.58,33.40) .. (14.58,30.88)
 .. controls (14.58,28.36) and (10.26,17.19) .. (9.18,15.39)
 .. controls (8.10,13.59) and (3.78,4.95) .. (3.78,4.95)
 -- (1.62,-5.49)
 -- (-4.86,-19.53)
 .. controls (-4.86,-19.53) and (-9.18,-25.29) .. (-4.86,-27.45)
 .. controls (-0.54,-29.61) and (4.50,-33.21) .. (7.02,-33.21)
 .. controls (9.54,-33.21) and (12.07,-41.14) .. (12.07,-41.14)
),
1,reverse ((-3.06,2.07)
 -- (-7.74,-9.09)
 -- (-11.70,-17.37)
 .. controls (-11.70,-17.37) and (-23.58,-25.65) .. (-22.14,-32.86)
 .. controls (-20.70,-40.06) and (-11.34,-44.38) .. (-11.34,-44.38)
 .. controls (-11.34,-44.38) and (-1.62,-46.18) .. (-0.54,-47.26)
 .. controls (0.54,-48.34) and (6.66,-54.46) .. (6.66,-54.46)
),
1,reverse ((-14.94,64.00)
 .. controls (-14.94,64.00) and (-18.18,60.40) .. (-19.26,55.72)
 .. controls (-20.34,51.04) and (-19.98,47.44) .. (-18.18,42.04)
 .. controls (-16.38,36.64) and (-7.38,33.40) .. (-5.22,32.68)
 .. controls (-3.06,31.96) and (3.06,35.20) .. (3.06,29.08)
 .. controls (3.06,22.95) and (3.78,15.39) .. (2.34,12.87)
 .. controls (0.90,10.35) and (-3.06,2.07) .. (-3.06,2.07)
));
draw_downscrap;
endfig;
beginfig(308);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-14.94,64.00)
 .. controls (-14.94,64.00) and (-18.18,60.40) .. (-19.26,55.72)
 .. controls (-20.34,51.04) and (-19.98,47.44) .. (-18.18,42.04)
 .. controls (-16.38,36.64) and (-7.38,33.40) .. (-5.22,32.68)
 .. controls (-3.06,31.96) and (3.06,35.20) .. (3.06,29.08)
 .. controls (3.06,22.95) and (3.78,15.39) .. (2.34,12.87)
 .. controls (0.90,10.35) and (-3.06,2.07) .. (-3.06,2.07)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.86,62.20)
 .. controls (-4.86,62.20) and (-4.86,58.24) .. (-0.54,56.08)
 .. controls (3.78,53.92) and (4.86,52.84) .. (5.94,50.32)
 .. controls (7.02,47.80) and (8.10,42.40) .. (9.18,40.24)
 .. controls (10.26,38.08) and (14.58,33.40) .. (14.58,30.88)
 .. controls (14.58,28.36) and (10.26,17.19) .. (9.18,15.39)
 .. controls (8.10,13.59) and (3.78,4.95) .. (3.78,4.95)
 -- (1.62,-5.49)
 -- (-4.86,-19.53)
 .. controls (-4.86,-19.53) and (-9.18,-25.29) .. (-4.86,-27.45)
 .. controls (-0.54,-29.61) and (4.50,-33.21) .. (7.02,-33.21)
 .. controls (9.54,-33.21) and (12.07,-41.14) .. (12.07,-41.14)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((2.88,38.44)
 .. controls (2.88,38.44) and (10.62,32.32) .. (9.36,28.18)
 .. controls (8.10,24.04) and (6.66,15.75) .. (5.94,15.03)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((14.22,46.72)
 -- (75.07,46.72)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-27.18,-37.18)
 -- (-77.23,-37.18)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-0.18,-40.60)
 .. controls (-0.18,-40.60) and (7.21,-43.84) .. (10.09,-47.26)
 .. controls (12.97,-50.68) and (16.57,-54.46) .. (15.31,-64.00)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.06,2.07)
 -- (-7.74,-9.09)
 -- (-11.70,-17.37)
 .. controls (-11.70,-17.37) and (-23.58,-25.65) .. (-22.14,-32.86)
 .. controls (-20.70,-40.06) and (-11.34,-44.38) .. (-11.34,-44.38)
 .. controls (-11.34,-44.38) and (-1.62,-46.18) .. (-0.54,-47.26)
 .. controls (0.54,-48.34) and (6.66,-54.46) .. (6.66,-54.46)
));
endfig;
beginfig(309);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char80 \char53 \mainfont{} etex,(-87.31,-37.18),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char53 \mainfont{} etex,(87.31,47.08),0.0,0);
endfig;
background:=(0.25000,0.60250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.60250, 1.00000);
current_scrap := "fromagereSP7@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP7";
beginfig(310);
draw_upscrap(1)(1,((16.75,-105.66)
 -- (18.91,-98.82)
 .. controls (18.91,-98.82) and (25.75,-95.94) .. (28.27,-95.94)
 .. controls (30.79,-95.94) and (31.51,-93.06) .. (32.95,-90.18)
 .. controls (34.39,-87.30) and (31.51,-80.82) .. (30.79,-78.66)
 .. controls (30.07,-76.50) and (28.27,-67.87) .. (28.27,-67.87)
 -- (25.03,-59.59)
 .. controls (25.03,-59.59) and (22.15,-49.87) .. (21.79,-46.63)
 .. controls (21.43,-43.39) and (21.07,-39.79) .. (19.27,-36.19)
 .. controls (17.47,-32.59) and (16.03,-27.19) .. (16.03,-27.19)
 -- (12.79,-14.59)
 .. controls (12.79,-14.59) and (9.91,-3.43) .. (9.55,-1.27)
 .. controls (9.19,0.89) and (8.47,7.01) .. (8.11,9.89)
 .. controls (7.75,12.77) and (7.03,17.09) .. (7.03,18.89)
 .. controls (7.03,20.69) and (3.79,26.09) .. (1.99,27.53)
 .. controls (0.19,28.97) and (-1.25,39.41) .. (-1.25,41.93)
 .. controls (-1.25,44.45) and (-3.41,52.37) .. (-4.49,57.05)
 .. controls (-5.57,61.73) and (-8.09,67.13) .. (-8.45,70.00)
 .. controls (-8.81,72.88) and (-12.41,78.65) .. (-13.85,80.81)
 .. controls (-15.29,82.97) and (-21.06,86.94) .. (-21.78,88.74)
 .. controls (-22.50,90.54) and (-23.94,94.14) .. (-25.02,98.10)
 .. controls (-26.10,102.06) and (-28.62,105.66) .. (-28.62,105.66)
),
1,((-34.39,102.78)
 .. controls (-34.39,102.78) and (-34.39,96.66) .. (-32.95,94.14)
 .. controls (-31.51,91.62) and (-28.98,83.33) .. (-28.98,83.33)
 -- (-23.22,79.01)
 .. controls (-23.22,79.01) and (-16.01,73.61) .. (-15.29,70.37)
 .. controls (-14.57,67.13) and (-10.97,59.21) .. (-10.97,57.41)
 .. controls (-10.97,55.61) and (-9.17,43.73) .. (-8.45,41.57)
 .. controls (-7.73,39.41) and (-4.85,30.05) .. (-4.49,27.53)
 .. controls (-4.13,25.01) and (-2.33,11.33) .. (-1.97,9.17)
 .. controls (-1.61,7.01) and (0.55,-3.79) .. (1.27,-5.95)
 .. controls (1.99,-8.11) and (4.15,-14.95) .. (4.15,-16.75)
 .. controls (4.15,-18.55) and (6.67,-27.91) .. (7.75,-29.71)
 .. controls (8.83,-31.51) and (12.79,-44.83) .. (12.79,-47.35)
 .. controls (12.79,-49.87) and (17.47,-65.71) .. (17.47,-67.87)
 .. controls (17.47,-70.03) and (18.55,-79.02) .. (18.91,-81.18)
 .. controls (19.27,-83.34) and (23.95,-88.38) .. (18.55,-89.46)
 .. controls (13.15,-90.54) and (8.11,-97.02) .. (8.11,-97.02)
 -- (6.67,-103.86)
));
draw_downscrap;
endfig;
beginfig(311);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-34.39,102.78)
 .. controls (-34.39,102.78) and (-34.39,96.66) .. (-32.95,94.14)
 .. controls (-31.51,91.62) and (-28.98,83.33) .. (-28.98,83.33)
 -- (-23.22,79.01)
 .. controls (-23.22,79.01) and (-16.01,73.61) .. (-15.29,70.37)
 .. controls (-14.57,67.13) and (-10.97,59.21) .. (-10.97,57.41)
 .. controls (-10.97,55.61) and (-9.17,43.73) .. (-8.45,41.57)
 .. controls (-7.73,39.41) and (-4.85,30.05) .. (-4.49,27.53)
 .. controls (-4.13,25.01) and (-2.33,11.33) .. (-1.97,9.17)
 .. controls (-1.61,7.01) and (0.55,-3.79) .. (1.27,-5.95)
 .. controls (1.99,-8.11) and (4.15,-14.95) .. (4.15,-16.75)
 .. controls (4.15,-18.55) and (6.67,-27.91) .. (7.75,-29.71)
 .. controls (8.83,-31.51) and (12.79,-44.83) .. (12.79,-47.35)
 .. controls (12.79,-49.87) and (17.47,-65.71) .. (17.47,-67.87)
 .. controls (17.47,-70.03) and (18.55,-79.02) .. (18.91,-81.18)
 .. controls (19.27,-83.34) and (23.95,-88.38) .. (18.55,-89.46)
 .. controls (13.15,-90.54) and (8.11,-97.02) .. (8.11,-97.02)
 -- (6.67,-103.86)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((16.75,-105.66)
 -- (18.91,-98.82)
 .. controls (18.91,-98.82) and (25.75,-95.94) .. (28.27,-95.94)
 .. controls (30.79,-95.94) and (31.51,-93.06) .. (32.95,-90.18)
 .. controls (34.39,-87.30) and (31.51,-80.82) .. (30.79,-78.66)
 .. controls (30.07,-76.50) and (28.27,-67.87) .. (28.27,-67.87)
 -- (25.03,-59.59)
 .. controls (25.03,-59.59) and (22.15,-49.87) .. (21.79,-46.63)
 .. controls (21.43,-43.39) and (21.07,-39.79) .. (19.27,-36.19)
 .. controls (17.47,-32.59) and (16.03,-27.19) .. (16.03,-27.19)
 -- (12.79,-14.59)
 .. controls (12.79,-14.59) and (9.91,-3.43) .. (9.55,-1.27)
 .. controls (9.19,0.89) and (8.47,7.01) .. (8.11,9.89)
 .. controls (7.75,12.77) and (7.03,17.09) .. (7.03,18.89)
 .. controls (7.03,20.69) and (3.79,26.09) .. (1.99,27.53)
 .. controls (0.19,28.97) and (-1.25,39.41) .. (-1.25,41.93)
 .. controls (-1.25,44.45) and (-3.41,52.37) .. (-4.49,57.05)
 .. controls (-5.57,61.73) and (-8.09,67.13) .. (-8.45,70.00)
 .. controls (-8.81,72.88) and (-12.41,78.65) .. (-13.85,80.81)
 .. controls (-15.29,82.97) and (-21.06,86.94) .. (-21.78,88.74)
 .. controls (-22.50,90.54) and (-23.94,94.14) .. (-25.02,98.10)
 .. controls (-26.10,102.06) and (-28.62,105.66) .. (-28.62,105.66)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((-4.49,42.11)
 .. controls (-4.49,42.11) and (1.45,11.33) .. (2.35,8.27)
));
endfig;
background:=(0.25000,0.70000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.70000, 1.00000);
current_scrap := "fromagereSP6@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP6";
beginfig(312);
ATTR__height := -1;
drawoptions();
l_pit(((0.72,92.88)
 .. controls (0.72,92.88) and (-4.33,104.40) .. (-4.33,109.80)
 .. controls (-4.33,115.20) and (-5.23,117.72) .. (-5.23,119.52)
 .. controls (-5.23,121.32) and (-8.83,125.64) .. (-12.07,125.64)
 .. controls (-15.31,125.64) and (-16.03,119.88) .. (-16.03,119.88)
 .. controls (-16.03,119.88) and (-18.91,111.96) .. (-20.35,109.80)
 .. controls (-21.78,107.64) and (-22.50,107.28) .. (-24.66,95.04)
 .. controls (-26.82,82.80) and (-20.34,76.68) .. (-20.34,76.68)
));
endfig;
beginfig(313);
draw_upscrap(1)(1,((32.21,-42.48)
 -- (36.53,-30.96)
 .. controls (36.53,-30.96) and (39.77,-21.60) .. (39.77,-19.45)
 .. controls (39.77,-17.29) and (39.41,-1.81) .. (37.25,2.51)
 .. controls (35.09,6.83) and (32.93,18.35) .. (31.85,19.80)
 .. controls (30.77,21.24) and (31.49,44.28) .. (29.34,46.08)
 .. controls (27.18,47.88) and (22.14,61.02) .. (20.34,64.62)
 .. controls (18.54,68.22) and (4.32,91.80) .. (4.32,93.96)
 .. controls (4.32,96.12) and (-1.27,103.32) .. (-0.91,106.56)
 .. controls (-0.55,109.80) and (-2.71,118.80) .. (-3.07,124.92)
 .. controls (-3.43,131.04) and (-15.31,131.76) .. (-15.31,131.76)
),
1,((-21.07,128.52)
 .. controls (-21.07,128.52) and (-17.47,123.48) .. (-18.19,122.04)
 .. controls (-18.91,120.60) and (-19.99,117.00) .. (-22.51,113.76)
 .. controls (-25.02,110.51) and (-29.70,101.87) .. (-30.06,99.36)
 .. controls (-30.42,96.84) and (-28.98,82.44) .. (-28.62,81.00)
 .. controls (-28.26,79.56) and (-26.10,74.88) .. (-24.30,71.64)
 .. controls (-22.50,68.40) and (-19.26,58.50) .. (-18.90,57.06)
 .. controls (-18.54,55.62) and (-16.74,44.64) .. (-17.47,38.88)
 .. controls (-18.19,33.12) and (-14.23,23.58) .. (-13.15,21.06)
 .. controls (-12.07,18.54) and (-9.55,11.34) .. (-9.55,11.34)
 .. controls (-9.55,11.34) and (-7.75,1.80) .. (-7.39,-0.36)
 .. controls (-7.03,-2.52) and (0.17,-14.40) .. (0.17,-14.40)
 -- (4.85,-26.28)
 -- (10.25,-41.40)
 -- (11.69,-48.60)
),
1,((11.69,-48.60)
 .. controls (11.69,-48.60) and (14.92,-51.84) .. (15.64,-55.08)
 .. controls (16.36,-58.32) and (18.52,-65.88) .. (18.88,-68.40)
 .. controls (19.24,-70.92) and (23.92,-85.68) .. (24.64,-87.84)
 .. controls (25.36,-90.00) and (25.36,-94.68) .. (25.36,-96.48)
 .. controls (25.36,-98.28) and (26.80,-101.16) .. (28.24,-104.76)
 .. controls (29.68,-108.36) and (31.48,-116.64) .. (31.84,-118.44)
 .. controls (32.20,-120.24) and (34.00,-131.76) .. (34.00,-131.76)
),
1,((39.76,-128.88)
 .. controls (38.68,-127.08) and (40.84,-121.32) .. (40.84,-121.32)
 -- (36.16,-110.88)
 .. controls (36.16,-110.88) and (33.28,-101.16) .. (32.92,-99.00)
 .. controls (32.56,-96.84) and (33.28,-92.52) .. (33.64,-90.72)
 .. controls (34.00,-88.92) and (28.60,-81.00) .. (27.52,-75.24)
 .. controls (26.44,-69.48) and (28.24,-66.24) .. (30.76,-61.20)
 .. controls (33.28,-56.16) and (32.21,-42.48) .. (32.21,-42.48)
));
draw_upscrap(1)(1,((8.09,26.28)
 .. controls (8.09,26.28) and (21.46,39.64) .. (23.21,39.24)
 .. controls (27.89,38.16) and (26.81,29.16) .. (26.81,29.16)
 .. controls (26.81,29.16) and (22.49,20.16) .. (22.49,17.64)
 .. controls (22.49,15.12) and (24.29,9.72) .. (24.29,9.72)
 -- (26.81,4.32)
 -- (31.85,-2.52)
 -- (34.01,-10.08)
 -- (34.37,-20.16)
 -- (34.01,-27.00)
 .. controls (34.01,-27.00) and (32.57,-30.96) .. (31.13,-32.40)
 .. controls (29.69,-33.84) and (27.53,-41.40) .. (27.53,-41.40)
 .. controls (27.53,-41.40) and (22.49,-35.64) .. (21.77,-33.84)
 .. controls (21.05,-32.04) and (18.89,-21.60) .. (18.89,-21.60)
 .. controls (18.89,-21.60) and (12.05,-11.52) .. (11.33,-6.12)
 .. controls (10.61,-0.72) and (8.45,8.64) .. (8.09,14.04)
 .. controls (7.73,19.44) and (8.09,26.28) .. (8.09,26.28)
));
draw_downscrap;
endfig;
beginfig(314);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-21.07,128.52)
 .. controls (-21.07,128.52) and (-17.47,123.48) .. (-18.19,122.04)
 .. controls (-18.91,120.60) and (-19.99,117.00) .. (-22.51,113.76)
 .. controls (-25.02,110.51) and (-29.70,101.87) .. (-30.06,99.36)
 .. controls (-30.42,96.84) and (-28.98,82.44) .. (-28.62,81.00)
 .. controls (-28.26,79.56) and (-26.10,74.88) .. (-24.30,71.64)
 .. controls (-22.50,68.40) and (-19.26,58.50) .. (-18.90,57.06)
 .. controls (-18.54,55.62) and (-16.74,44.64) .. (-17.47,38.88)
 .. controls (-18.19,33.12) and (-14.23,23.58) .. (-13.15,21.06)
 .. controls (-12.07,18.54) and (-9.55,11.34) .. (-9.55,11.34)
 .. controls (-9.55,11.34) and (-7.75,1.80) .. (-7.39,-0.36)
 .. controls (-7.03,-2.52) and (0.17,-14.40) .. (0.17,-14.40)
 -- (4.85,-26.28)
 -- (10.25,-41.40)
 -- (11.69,-48.60)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((8.09,26.28)
 .. controls (8.09,26.28) and (21.46,39.64) .. (23.21,39.24)
 .. controls (27.89,38.16) and (26.81,29.16) .. (26.81,29.16)
 .. controls (26.81,29.16) and (22.49,20.16) .. (22.49,17.64)
 .. controls (22.49,15.12) and (24.29,9.72) .. (24.29,9.72)
 -- (26.81,4.32)
 -- (31.85,-2.52)
 -- (34.01,-10.08)
 -- (34.37,-20.16)
 -- (34.01,-27.00)
 .. controls (34.01,-27.00) and (32.57,-30.96) .. (31.13,-32.40)
 .. controls (29.69,-33.84) and (27.53,-41.40) .. (27.53,-41.40)
 .. controls (27.53,-41.40) and (22.49,-35.64) .. (21.77,-33.84)
 .. controls (21.05,-32.04) and (18.89,-21.60) .. (18.89,-21.60)
 .. controls (18.89,-21.60) and (12.05,-11.52) .. (11.33,-6.12)
 .. controls (10.61,-0.72) and (8.45,8.64) .. (8.09,14.04)
 .. controls (7.73,19.44) and (8.09,26.28) .. (8.09,26.28)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((32.21,-42.48)
 -- (36.53,-30.96)
 .. controls (36.53,-30.96) and (39.77,-21.60) .. (39.77,-19.45)
 .. controls (39.77,-17.29) and (39.41,-1.81) .. (37.25,2.51)
 .. controls (35.09,6.83) and (32.93,18.35) .. (31.85,19.80)
 .. controls (30.77,21.24) and (31.49,44.28) .. (29.34,46.08)
 .. controls (27.18,47.88) and (22.14,61.02) .. (20.34,64.62)
 .. controls (18.54,68.22) and (4.32,91.80) .. (4.32,93.96)
 .. controls (4.32,96.12) and (-1.27,103.32) .. (-0.91,106.56)
 .. controls (-0.55,109.80) and (-2.71,118.80) .. (-3.07,124.92)
 .. controls (-3.43,131.04) and (-15.31,131.76) .. (-15.31,131.76)
));
drawoptions();
p_camp((29.33,12.24),0.0,2.00,(1,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((-19.98,50.04)
 -- (-80.45,50.04)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((39.76,-128.88)
 .. controls (38.68,-127.08) and (40.84,-121.32) .. (40.84,-121.32)
 -- (36.16,-110.88)
 .. controls (36.16,-110.88) and (33.28,-101.16) .. (32.92,-99.00)
 .. controls (32.56,-96.84) and (33.28,-92.52) .. (33.64,-90.72)
 .. controls (34.00,-88.92) and (28.60,-81.00) .. (27.52,-75.24)
 .. controls (26.44,-69.48) and (28.24,-66.24) .. (30.76,-61.20)
 .. controls (33.28,-56.16) and (32.21,-42.48) .. (32.21,-42.48)
));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((16.01,-36.54)
 .. controls (16.01,-36.54) and (24.10,-52.74) .. (23.56,-60.48)
 .. controls (23.02,-68.22) and (23.02,-72.54) .. (23.02,-72.54)
 -- (25.36,-82.08)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.69,-48.60)
 .. controls (11.69,-48.60) and (14.92,-51.84) .. (15.64,-55.08)
 .. controls (16.36,-58.32) and (18.52,-65.88) .. (18.88,-68.40)
 .. controls (19.24,-70.92) and (23.92,-85.68) .. (24.64,-87.84)
 .. controls (25.36,-90.00) and (25.36,-94.68) .. (25.36,-96.48)
 .. controls (25.36,-98.28) and (26.80,-101.16) .. (28.24,-104.76)
 .. controls (29.68,-108.36) and (31.48,-116.64) .. (31.84,-118.44)
 .. controls (32.20,-120.24) and (34.00,-131.76) .. (34.00,-131.76)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((4.85,106.92)
 -- (84.05,106.93)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((40.49,10.07)
 -- (84.05,10.08)
));
endfig;
beginfig(315);
drawoptions();
p_label.urt(btex \thaltitude \thfb\char49 \char48 \char53 \char57 \mainfont{} etex,(11.52,80.10),0.0,1);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char71 \char114 \char97 \char110 \char100 \char101 \ \char115 \char97 \char108 \char108 \char101 \mainfont{} etex,(-95.93,49.67),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thhugesize \thfb\char66 \char105 \char118 \char111 \char117 \char97 \char99 \ \char100 \char101 \ \char108 \char97 \ \char70 \char114 \char111 \char109 \char97 \char103 \accent18 \char101 \char114 \char101 \mainfont{} etex,(95.93,9.36),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char49 \char55 \mainfont{} etex,(94.85,106.21),0.0,0);
endfig;
background:=(0.25000,0.82750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.82750, 1.00000);
current_scrap := "fromagereSP5@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP5";
beginfig(316);
draw_upscrap(1)(1,((-18.90,30.23)
 -- (-18.54,19.44)
 .. controls (-18.54,19.44) and (-20.34,12.24) .. (-20.34,10.44)
 .. controls (-20.34,8.64) and (-20.70,-1.08) .. (-18.54,-2.52)
 .. controls (-16.38,-3.96) and (-14.22,-5.76) .. (-13.50,-8.28)
 .. controls (-12.78,-10.80) and (-10.26,-21.96) .. (-10.26,-21.96)
 -- (-2.34,-47.16)
 .. controls (-2.34,-47.16) and (1.62,-58.31) .. (4.86,-59.76)
 .. controls (8.10,-61.20) and (14.94,-65.52) .. (14.94,-65.52)
),
1,((20.70,-62.28)
 -- (13.86,-57.96)
 .. controls (13.86,-57.96) and (9.90,-55.44) .. (7.38,-53.64)
 .. controls (4.86,-51.83) and (4.14,-47.52) .. (3.06,-45.00)
 .. controls (1.98,-42.48) and (-0.18,-36.36) .. (-0.18,-36.36)
 .. controls (-0.18,-36.36) and (-2.70,-26.28) .. (-3.06,-24.12)
 .. controls (-3.42,-21.96) and (-6.30,-8.28) .. (-7.02,-5.40)
 .. controls (-7.74,-2.52) and (-10.62,1.80) .. (-10.98,3.96)
 .. controls (-11.34,6.12) and (-10.98,9.72) .. (-10.98,14.40)
 .. controls (-10.98,19.08) and (-5.57,29.51) .. (-5.57,29.51)
));
draw_downscrap;
endfig;
beginfig(317);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((20.70,-62.28)
 -- (13.86,-57.96)
 .. controls (13.86,-57.96) and (9.90,-55.44) .. (7.38,-53.64)
 .. controls (4.86,-51.83) and (4.14,-47.52) .. (3.06,-45.00)
 .. controls (1.98,-42.48) and (-0.18,-36.36) .. (-0.18,-36.36)
 .. controls (-0.18,-36.36) and (-2.70,-26.28) .. (-3.06,-24.12)
 .. controls (-3.42,-21.96) and (-6.30,-8.28) .. (-7.02,-5.40)
 .. controls (-7.74,-2.52) and (-10.62,1.80) .. (-10.98,3.96)
 .. controls (-11.34,6.12) and (-10.98,9.72) .. (-10.98,14.40)
 .. controls (-10.98,19.08) and (-5.57,29.51) .. (-5.57,29.51)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-18.90,30.23)
 -- (-18.54,19.44)
 .. controls (-18.54,19.44) and (-20.34,12.24) .. (-20.34,10.44)
 .. controls (-20.34,8.64) and (-20.70,-1.08) .. (-18.54,-2.52)
 .. controls (-16.38,-3.96) and (-14.22,-5.76) .. (-13.50,-8.28)
 .. controls (-12.78,-10.80) and (-10.26,-21.96) .. (-10.26,-21.96)
 -- (-2.34,-47.16)
 .. controls (-2.34,-47.16) and (1.62,-58.31) .. (4.86,-59.76)
 .. controls (8.10,-61.20) and (14.94,-65.52) .. (14.94,-65.52)
));
drawoptions();
p_gradient((-8.46,65.52),0.0,1.00,(0,0));
endfig;
beginfig(318);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char86 \char101 \char114 \char115 \ \char108 \char39 \char101 \char110 \char116 \char114 \thfc\char233 \thfb\char101 \ \char100 \char117 \ \char103 \char111 \char117 \char102 \char102 \char114 \char101 \ \char100 \char101 \ \char108 \char97 \ \char70 \char114 \char111 \char109 \char97 \char103 \accent18 \char101 \char114 \char101 \mainfont{} etex,(-9.90,46.08),0.0,0);
drawoptions();
p_label.lft(btex \thaltitude \thfb\char49 \char48 \char56 \char51 \mainfont{} etex,(-19.98,3.42),0.0,1);
endfig;
background:=(0.96250,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.96250, 0.25000, 1.00000);
current_scrap := "fromagereSP26@20161022fromagere.D35projet";
ATTR__scrap := "fromagereSP26";
beginfig(319);
current_src := "20160711fromagere.th2 [1931]";
string area_border[];
area_border[1] := "l362-33992-19618";
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle(((-1.36,22.51)
 .. controls (-1.36,22.51) and (-13.06,21.97) .. (-12.88,16.57)
 .. controls (-12.70,11.17) and (-10.17,-1.97) .. (2.24,-2.51)
 .. controls (14.66,-3.05) and (23.12,6.13) .. (19.87,11.35)
 .. controls (16.63,16.57) and (1.70,15.49) .. (1.70,15.49)
 -- cycle
)));
endfig;
beginfig(320);
draw_upscrap(1)(1,((-9.46,48.07)
 .. controls (-9.46,48.07) and (-17.56,49.87) .. (-18.64,47.53)
 .. controls (-19.72,45.19) and (-22.78,45.01) .. (-19.18,38.35)
 .. controls (-15.58,31.69) and (-11.08,22.87) .. (-11.08,21.43)
 .. controls (-11.08,19.99) and (-8.92,14.05) .. (-7.66,10.27)
 .. controls (-6.40,6.49) and (-3.70,3.79) .. (1.16,4.33)
 .. controls (6.02,4.87) and (17.71,7.39) .. (19.52,0.37)
 .. controls (21.32,-6.65) and (26.36,-1.97) .. (26.54,-7.55)
 .. controls (26.72,-13.13) and (30.50,-20.33) .. (29.78,-26.27)
 .. controls (29.06,-32.22) and (31.94,-35.64) .. (31.76,-38.52)
 .. controls (31.58,-41.40) and (33.56,-44.64) .. (38.78,-47.16)
 .. controls (44.00,-49.68) and (49.41,-50.94) .. (49.41,-50.94)
),
1,((48.87,-42.48)
 .. controls (48.87,-42.48) and (41.30,-42.84) .. (39.86,-41.04)
 .. controls (38.42,-39.24) and (38.42,-36.72) .. (37.52,-30.24)
 .. controls (36.62,-23.75) and (33.74,-17.45) .. (33.20,-14.57)
 .. controls (32.66,-11.69) and (34.47,-2.69) .. (30.32,1.09)
 .. controls (26.18,4.87) and (22.03,8.11) .. (22.03,8.11)
 .. controls (22.03,8.11) and (15.37,13.69) .. (9.62,12.25)
 .. controls (3.86,10.81) and (-0.64,13.33) .. (-2.62,17.11)
 .. controls (-4.60,20.89) and (-10.54,31.51) .. (-10.54,33.67)
 .. controls (-10.54,35.83) and (-11.62,38.89) .. (-6.40,38.35)
));
draw_downscrap;
endfig;
beginfig(321);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-9.46,48.07)
 .. controls (-9.46,48.07) and (-17.56,49.87) .. (-18.64,47.53)
 .. controls (-19.72,45.19) and (-22.78,45.01) .. (-19.18,38.35)
 .. controls (-15.58,31.69) and (-11.08,22.87) .. (-11.08,21.43)
 .. controls (-11.08,19.99) and (-8.92,14.05) .. (-7.66,10.27)
 .. controls (-6.40,6.49) and (-3.70,3.79) .. (1.16,4.33)
 .. controls (6.02,4.87) and (17.71,7.39) .. (19.52,0.37)
 .. controls (21.32,-6.65) and (26.36,-1.97) .. (26.54,-7.55)
 .. controls (26.72,-13.13) and (30.50,-20.33) .. (29.78,-26.27)
 .. controls (29.06,-32.22) and (31.94,-35.64) .. (31.76,-38.52)
 .. controls (31.58,-41.40) and (33.56,-44.64) .. (38.78,-47.16)
 .. controls (44.00,-49.68) and (49.41,-50.94) .. (49.41,-50.94)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-46.72,38.35)
 -- (-50.14,34.93)
 -- (37.70,-60.84)
 -- (42.56,-57.06)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-13.59,-5.03)
 -- (-24.57,-16.91)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((48.87,-42.48)
 .. controls (48.87,-42.48) and (41.30,-42.84) .. (39.86,-41.04)
 .. controls (38.42,-39.24) and (38.42,-36.72) .. (37.52,-30.24)
 .. controls (36.62,-23.75) and (33.74,-17.45) .. (33.20,-14.57)
 .. controls (32.66,-11.69) and (34.47,-2.69) .. (30.32,1.09)
 .. controls (26.18,4.87) and (22.03,8.11) .. (22.03,8.11)
 .. controls (22.03,8.11) and (15.37,13.69) .. (9.62,12.25)
 .. controls (3.86,10.81) and (-0.64,13.33) .. (-2.62,17.11)
 .. controls (-4.60,20.89) and (-10.54,31.51) .. (-10.54,33.67)
 .. controls (-10.54,35.83) and (-11.62,38.89) .. (-6.40,38.35)
));
ATTR__height := -1;
drawoptions();
l_mapconnection(((52.65,-45.72)
 -- (99.28,-45.71)
));
ATTR__height := -1;
drawoptions();
l_mapconnection(((-0.10,43.03)
 -- (43.63,43.04)
));
drawoptions();
p_airdraught_winter((-20.62,26.65),208.3,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_rockedge(((-24.94,36.01)
 -- (-38.98,49.87)
 -- (-49.60,60.67)
 -- (-89.02,60.66)
));
endfig;
beginfig(322);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char83 \char104 \char117 \char110 \char116 \ \char115 \char105 \char112 \char104 \char111 \char110 \mainfont{} etex,(-28.53,-20.33),0.0,0);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char49 \char51 \char48 \char48 \ \char108 \char112 \char115 \ \char49 \char50 \char47 \char49 \char48 \char47 \char50 \char48 \char49 \char54 \ \char49 \char56 \char58 \char52 \char53 \mainfont{} etex,(-99.28,60.84),0.0,0);
endfig;
current_scrap := "fromagereSP26@20161022fromagere.D35projet";
beginfig(323);
draw_upscrap(1)(1,((-9.46,48.07)
 .. controls (-9.46,48.07) and (-17.56,49.87) .. (-18.64,47.53)
 .. controls (-19.72,45.19) and (-22.78,45.01) .. (-19.18,38.35)
 .. controls (-15.58,31.69) and (-11.08,22.87) .. (-11.08,21.43)
 .. controls (-11.08,19.99) and (-8.92,14.05) .. (-7.66,10.27)
 .. controls (-6.40,6.49) and (-3.70,3.79) .. (1.16,4.33)
 .. controls (6.02,4.87) and (17.71,7.39) .. (19.52,0.37)
 .. controls (21.32,-6.65) and (26.36,-1.97) .. (26.54,-7.55)
 .. controls (26.72,-13.13) and (30.50,-20.33) .. (29.78,-26.27)
 .. controls (29.06,-32.22) and (31.94,-35.64) .. (31.76,-38.52)
 .. controls (31.58,-41.40) and (33.56,-44.64) .. (38.78,-47.16)
 .. controls (44.00,-49.68) and (49.41,-50.94) .. (49.41,-50.94)
),
1,((48.87,-42.48)
 .. controls (48.87,-42.48) and (41.30,-42.84) .. (39.86,-41.04)
 .. controls (38.42,-39.24) and (38.42,-36.72) .. (37.52,-30.24)
 .. controls (36.62,-23.75) and (33.74,-17.45) .. (33.20,-14.57)
 .. controls (32.66,-11.69) and (34.47,-2.69) .. (30.32,1.09)
 .. controls (26.18,4.87) and (22.03,8.11) .. (22.03,8.11)
 .. controls (22.03,8.11) and (15.37,13.69) .. (9.62,12.25)
 .. controls (3.86,10.81) and (-0.64,13.33) .. (-2.62,17.11)
 .. controls (-4.60,20.89) and (-10.54,31.51) .. (-10.54,33.67)
 .. controls (-10.54,35.83) and (-11.62,38.89) .. (-6.40,38.35)
));
draw_downscrap;
endfig;
background:=(0.25000,0.88750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.88750, 1.00000);
current_scrap := "D35_20161210SP25@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP25";
beginfig(324);
draw_upscrap(1)(1,((105.75,-285.64)
 .. controls (106.11,-286.50) and (106.96,-288.57) .. (107.90,-289.61)
 .. controls (108.84,-290.65) and (109.15,-291.03) .. (112.12,-291.11)
 .. controls (115.01,-291.18) and (114.87,-290.74) .. (115.88,-290.98)
 .. controls (116.88,-291.22) and (118.88,-292.63) .. (118.88,-292.63)
),
1,((122.53,-290.56)
 .. controls (122.53,-290.56) and (120.10,-287.83) .. (119.41,-286.45)
 .. controls (118.72,-285.08) and (117.42,-282.75) .. (117.01,-281.90)
 .. controls (116.60,-281.04) and (115.60,-279.12) .. (115.60,-279.12)
),
1,((110.99,-280.27)
 .. controls (110.99,-280.27) and (116.18,-289.70) .. (108.47,-282.61)
));
draw_downscrap;
endfig;
beginfig(325);
ATTR__survey := "D35_20161210.D35projet";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((122.53,-290.56)
 .. controls (122.53,-290.56) and (120.10,-287.83) .. (119.41,-286.45)
 .. controls (118.72,-285.08) and (117.42,-282.75) .. (117.01,-281.90)
 .. controls (116.60,-281.04) and (115.60,-279.12) .. (115.60,-279.12)
));
ATTR__height := -1;
drawoptions();
l_border_presumed(((115.60,-279.12)
 .. controls (115.60,-279.12) and (113.45,-274.65) .. (112.36,-272.41)
));
ATTR__height := -1;
drawoptions();
l_border_presumed(((107.59,-273.13)
 -- (108.96,-275.90)
 -- (110.99,-280.27)
));
ATTR__height := -1;
drawoptions();
l_border_presumed(((103.85,-248.15)
 .. controls (103.85,-248.15) and (98.43,-183.73) .. (83.67,-157.45)
 .. controls (68.91,-131.17) and (5.90,-51.97) .. (3.38,-27.85)
 .. controls (0.86,-3.74) and (-44.14,136.66) .. (-53.86,151.78)
 .. controls (-63.58,166.90) and (-97.42,224.14) .. (-102.82,248.62)
 .. controls (-108.22,273.10) and (-124.78,297.58) .. (-124.78,297.58)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((110.99,-280.27)
 .. controls (110.99,-280.27) and (116.18,-289.70) .. (108.47,-282.61)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((105.75,-285.64)
 .. controls (106.11,-286.50) and (106.96,-288.57) .. (107.90,-289.61)
 .. controls (108.84,-290.65) and (109.15,-291.03) .. (112.12,-291.11)
 .. controls (115.01,-291.18) and (114.87,-290.74) .. (115.88,-290.98)
 .. controls (116.88,-291.22) and (118.88,-292.63) .. (118.88,-292.63)
));
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((101.75,-278.79),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_waterflow_permanent(((114.24,-280.53)
 .. controls (114.24,-280.53) and (117.91,-288.63) .. (120.07,-290.77)
 .. controls (122.25,-292.91) and (124.23,-296.51) .. (124.78,-297.58)
));
endfig;
beginfig(326);
ATTR__height := -1;
drawoptions();
l_label(btex \thnormalsize \thfb\char69 {}\char120 {}\char112 {}\char108 {}\char111 {}\ \char110 {}\char111 {}\char110 {}\ \ \char116 {}\char111 {}\char112 {}\char111 {}\char116 {}\thfc\char233 {}\thfb\char44 {}\ \char97 {}\char114 {}\char114 {}\accent94 \char101 {}\char116 {}\ \char99 {}\char97 {}\ \char99 {}\char111 {}\char110 {}\char116 {}\char105 {}\char110 {}\char117 {}\char101 {}\ \char58 {}\char41 {}\mainfont{} etex,((-43.42,260.50)
 .. controls (-43.42,260.50) and (-36.22,203.26) .. (3.02,156.46)
 .. controls (42.26,109.66) and (56.17,20.84) .. (69.26,-8.78)
));
endfig;
background:=(0.25000,0.88000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.88000, 1.00000);
current_scrap := "D35_20161210SP24@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP24";
beginfig(327);
draw_upscrap(1)(1,((4.52,-6.08)
 .. controls (4.52,-6.08) and (4.22,-3.41) .. (4.10,-2.24)
 .. controls (3.99,-1.07) and (1.69,3.21) .. (1.05,5.17)
 .. controls (0.43,7.10) and (-0.61,7.52) .. (-0.87,8.15)
),
1,((-4.52,6.08)
 .. controls (-4.52,6.08) and (-2.64,3.72) .. (-2.03,2.43)
 .. controls (-1.41,1.13) and (-0.57,-0.95) .. (-0.54,-2.58)
 .. controls (-0.52,-4.21) and (0.42,-8.15) .. (0.42,-8.15)
));
draw_downscrap;
endfig;
beginfig(328);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.52,-6.08)
 .. controls (4.52,-6.08) and (4.22,-3.41) .. (4.10,-2.24)
 .. controls (3.99,-1.07) and (1.69,3.21) .. (1.05,5.17)
 .. controls (0.43,7.10) and (-0.61,7.52) .. (-0.87,8.15)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.52,6.08)
 .. controls (-4.52,6.08) and (-2.64,3.72) .. (-2.03,2.43)
 .. controls (-1.41,1.13) and (-0.57,-0.95) .. (-0.54,-2.58)
 .. controls (-0.52,-4.21) and (0.42,-8.15) .. (0.42,-8.15)
));
endfig;
background:=(0.25000,0.86500,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.86500, 1.00000);
current_scrap := "D35_20161210SP23@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP23";
beginfig(329);
draw_upscrap(1)(1,((-2.82,1.15)
 .. controls (-2.50,-1.54) and (-0.51,-3.36) .. (-0.51,-3.36)
),
0,reverse ((2.82,-1.47)
 .. controls (2.82,-1.47) and (-0.38,-2.32) .. (-0.51,-3.36)
),
1,((2.82,-1.47)
 .. controls (2.82,-1.47) and (0.93,1.59) .. (1.28,3.22)
),
0,reverse ((-2.82,1.15)
 .. controls (-2.82,1.15) and (-0.78,3.36) .. (1.28,3.22)
));
draw_downscrap;
endfig;
beginfig(330);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2.82,1.15)
 .. controls (-2.50,-1.54) and (-0.51,-3.36) .. (-0.51,-3.36)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2.82,-1.47)
 .. controls (2.82,-1.47) and (0.93,1.59) .. (1.28,3.22)
));
endfig;
background:=(0.25000,0.85000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.85000, 1.00000);
current_scrap := "D35_20161210SP22@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP22";
beginfig(331);
draw_upscrap(1)(1,((9.47,-7.52)
 .. controls (9.47,-7.52) and (8.86,-2.06) .. (7.45,0.34)
 .. controls (6.04,2.75) and (4.18,5.89) .. (4.40,5.89)
 .. controls (4.62,5.88) and (2.32,8.68) .. (2.32,8.68)
),
0,((2.32,8.68)
 .. controls (2.32,8.68) and (-0.75,8.50) .. (-1.01,6.79)
),
1,((-1.01,6.79)
 .. controls (-1.01,6.79) and (2.99,2.76) .. (3.03,1.92)
 .. controls (3.07,1.07) and (3.39,-0.65) .. (1.59,1.16)
 .. controls (-0.21,2.96) and (-0.97,4.06) .. (-0.97,4.06)
),
1,((-3.95,1.81)
 .. controls (-3.95,1.81) and (-2.22,0.33) .. (-1.97,-0.09)
 .. controls (-1.72,-0.50) and (0.58,-3.50) .. (0.88,-3.73)
 .. controls (1.18,-3.96) and (1.89,-5.67) .. (2.25,-7.08)
 .. controls (2.62,-8.51) and (2.63,-8.68) .. (2.63,-8.68)
));
draw_downscrap;
endfig;
beginfig(332);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((9.47,-7.52)
 .. controls (9.47,-7.52) and (8.86,-2.06) .. (7.45,0.34)
 .. controls (6.04,2.75) and (4.18,5.89) .. (4.40,5.89)
 .. controls (4.62,5.88) and (2.32,8.68) .. (2.32,8.68)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1.01,6.79)
 .. controls (-1.01,6.79) and (2.99,2.76) .. (3.03,1.92)
 .. controls (3.07,1.07) and (3.39,-0.65) .. (1.59,1.16)
 .. controls (-0.21,2.96) and (-0.97,4.06) .. (-0.97,4.06)
));
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((-9.47,6.63),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.95,1.81)
 .. controls (-3.95,1.81) and (-2.22,0.33) .. (-1.97,-0.09)
 .. controls (-1.72,-0.50) and (0.58,-3.50) .. (0.88,-3.73)
 .. controls (1.18,-3.96) and (1.89,-5.67) .. (2.25,-7.08)
 .. controls (2.62,-8.51) and (2.63,-8.68) .. (2.63,-8.68)
));
endfig;
background:=(0.25000,0.82750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.82750, 1.00000);
current_scrap := "D35_20161210SP21@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP21";
beginfig(333);
draw_upscrap(1)(1,((-4.30,-9.49)
 .. controls (-4.30,-9.49) and (-4.29,-8.58) .. (-6.27,-7.89)
 .. controls (-8.23,-7.21) and (-9.24,-6.24) .. (-10.20,-5.52)
 .. controls (-11.16,-4.81) and (-13.37,-3.95) .. (-14.11,-3.49)
 .. controls (-14.84,-3.04) and (-17.56,-2.95) .. (-16.28,0.02)
 .. controls (-15.00,2.98) and (-15.75,6.97) .. (-16.05,8.33)
),
1,reverse ((-2.27,-6.77)
 .. controls (-2.27,-6.77) and (-2.55,-5.89) .. (-2.47,-4.88)
 .. controls (-2.39,-3.87) and (-0.99,-2.51) .. (-0.60,-2.13)
 .. controls (-0.20,-1.75) and (0.22,0.95) .. (-1.45,1.85)
 .. controls (-3.11,2.75) and (-5.08,3.17) .. (-7.17,2.19)
 .. controls (-9.27,1.20) and (-9.33,0.03) .. (-10.02,1.93)
 .. controls (-10.70,3.84) and (-9.32,8.59) .. (-9.21,9.49)
));
draw_downscrap;
endfig;
beginfig(334);
ATTR__height := -1;
drawoptions();
l_rockedge(((2.70,-7.59)
 -- (14.41,1.86)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2.27,-6.77)
 .. controls (-2.27,-6.77) and (-2.55,-5.89) .. (-2.47,-4.88)
 .. controls (-2.39,-3.87) and (-0.99,-2.51) .. (-0.60,-2.13)
 .. controls (-0.20,-1.75) and (0.22,0.95) .. (-1.45,1.85)
 .. controls (-3.11,2.75) and (-5.08,3.17) .. (-7.17,2.19)
 .. controls (-9.27,1.20) and (-9.33,0.03) .. (-10.02,1.93)
 .. controls (-10.70,3.84) and (-9.32,8.59) .. (-9.21,9.49)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.30,-9.49)
 .. controls (-4.30,-9.49) and (-4.29,-8.58) .. (-6.27,-7.89)
 .. controls (-8.23,-7.21) and (-9.24,-6.24) .. (-10.20,-5.52)
 .. controls (-11.16,-4.81) and (-13.37,-3.95) .. (-14.11,-3.49)
 .. controls (-14.84,-3.04) and (-17.56,-2.95) .. (-16.28,0.02)
 .. controls (-15.00,2.98) and (-15.75,6.97) .. (-16.05,8.33)
));
endfig;
beginfig(335);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char82 \char52 \mainfont{} etex,(17.56,4.17),0.0,0);
endfig;
background:=(0.25000,0.81250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.81250, 1.00000);
current_scrap := "D35_20161210SP20@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP20";
beginfig(336);
draw_upscrap(1)(1,((4.85,-4.84)
 .. controls (4.85,-4.84) and (4.46,-1.81) .. (4.41,-1.23)
 .. controls (4.36,-0.64) and (4.79,1.97) .. (4.31,3.07)
 .. controls (3.83,4.17) and (2.17,5.74) .. (0.75,6.33)
 .. controls (-0.69,6.93) and (-0.62,8.03) .. (-0.62,8.03)
),
1,reverse ((-1.31,-8.03)
 .. controls (-1.31,-8.03) and (-2.57,-6.59) .. (-3.19,-5.96)
 .. controls (-3.81,-5.32) and (-4.85,-3.32) .. (-4.46,-1.96)
 .. controls (-4.07,-0.59) and (-2.25,0.72) .. (-2.03,1.32)
 .. controls (-1.82,1.92) and (-2.20,4.72) .. (-2.65,5.31)
),
0,reverse ((4.85,-4.84)
 .. controls (4.85,-4.84) and (-1.76,-6.37) .. (-1.31,-8.03)
));
draw_downscrap;
endfig;
beginfig(337);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1.31,-8.03)
 .. controls (-1.31,-8.03) and (-2.57,-6.59) .. (-3.19,-5.96)
 .. controls (-3.81,-5.32) and (-4.85,-3.32) .. (-4.46,-1.96)
 .. controls (-4.07,-0.59) and (-2.25,0.72) .. (-2.03,1.32)
 .. controls (-1.82,1.92) and (-2.20,4.72) .. (-2.65,5.31)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.85,-4.84)
 .. controls (4.85,-4.84) and (4.46,-1.81) .. (4.41,-1.23)
 .. controls (4.36,-0.64) and (4.79,1.97) .. (4.31,3.07)
 .. controls (3.83,4.17) and (2.17,5.74) .. (0.75,6.33)
 .. controls (-0.69,6.93) and (-0.62,8.03) .. (-0.62,8.03)
));
endfig;
background:=(0.25000,0.79750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.79750, 1.00000);
current_scrap := "D35_20161210SP19@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP19";
beginfig(338);
draw_upscrap(1)(1,((4.63,-8.30)
 .. controls (4.63,-8.30) and (3.95,-7.48) .. (3.53,-5.48)
 .. controls (3.11,-3.50) and (2.73,-1.89) .. (3.31,0.27)
 .. controls (3.88,2.43) and (2.58,5.08) .. (2.47,5.66)
 .. controls (2.37,6.25) and (2.29,8.72) .. (2.29,8.72)
),
0,((2.29,8.72)
 .. controls (-4.63,7.87) and (-3.87,5.53) .. (-3.87,5.53)
),
1,((-3.87,5.53)
 .. controls (-3.16,5.12) and (-2.89,5.67) .. (-2.55,4.94)
 .. controls (-2.23,4.23) and (-2.15,4.59) .. (-2.42,1.50)
 .. controls (-2.68,-1.58) and (-1.67,-2.26) .. (-1.39,-3.35)
 .. controls (-1.11,-4.45) and (0.03,-8.72) .. (0.03,-8.72)
));
draw_downscrap;
endfig;
beginfig(339);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.87,5.53)
 .. controls (-3.16,5.12) and (-2.89,5.67) .. (-2.55,4.94)
 .. controls (-2.23,4.23) and (-2.15,4.59) .. (-2.42,1.50)
 .. controls (-2.68,-1.58) and (-1.67,-2.26) .. (-1.39,-3.35)
 .. controls (-1.11,-4.45) and (0.03,-8.72) .. (0.03,-8.72)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((4.63,-8.30)
 .. controls (4.63,-8.30) and (3.95,-7.48) .. (3.53,-5.48)
 .. controls (3.11,-3.50) and (2.73,-1.89) .. (3.31,0.27)
 .. controls (3.88,2.43) and (2.58,5.08) .. (2.47,5.66)
 .. controls (2.37,6.25) and (2.29,8.72) .. (2.29,8.72)
));
endfig;
current_scrap := "D35_20161210SP18@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP18";
beginfig(340);
draw_upscrap(1)(1,((7.34,-13.39)
 .. controls (7.34,-13.39) and (6.99,-13.23) .. (5.24,-11.21)
 .. controls (3.49,-9.20) and (4.51,-9.49) .. (1.94,-6.11)
 .. controls (-0.62,-2.73) and (-0.22,0.45) .. (-0.41,3.47)
 .. controls (-0.60,6.49) and (-2.74,16.30) .. (-2.74,16.30)
),
1,reverse ((-4.27,-0.85)
 .. controls (-4.27,-0.85) and (-4.46,3.89) .. (-5.05,5.80)
 .. controls (-5.65,7.71) and (-6.82,14.45) .. (-7.34,15.87)
),
1,reverse ((3.67,-16.30)
 .. controls (3.67,-16.30) and (2.08,-13.30) .. (1.36,-12.53)
 .. controls (0.65,-11.75) and (0.61,-12.25) .. (-0.20,-10.30)
 .. controls (-1.01,-8.35) and (-0.73,-6.25) .. (-3.66,-5.00)
 .. controls (-5.09,-4.40) and (-4.11,-3.03) .. (-4.27,-0.85)
));
draw_downscrap;
endfig;
beginfig(341);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((3.67,-16.30)
 .. controls (3.67,-16.30) and (2.08,-13.30) .. (1.36,-12.53)
 .. controls (0.65,-11.75) and (0.61,-12.25) .. (-0.20,-10.30)
 .. controls (-1.01,-8.35) and (-0.73,-6.25) .. (-3.66,-5.00)
 .. controls (-5.09,-4.40) and (-4.11,-3.03) .. (-4.27,-0.85)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-4.27,-0.85)
 .. controls (-4.27,-0.85) and (-4.46,3.89) .. (-5.05,5.80)
 .. controls (-5.65,7.71) and (-6.82,14.45) .. (-7.34,15.87)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((7.34,-13.39)
 .. controls (7.34,-13.39) and (6.99,-13.23) .. (5.24,-11.21)
 .. controls (3.49,-9.20) and (4.51,-9.49) .. (1.94,-6.11)
 .. controls (-0.62,-2.73) and (-0.22,0.45) .. (-0.41,3.47)
 .. controls (-0.60,6.49) and (-2.74,16.30) .. (-2.74,16.30)
));
endfig;
background:=(0.25000,0.76750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.76750, 1.00000);
current_scrap := "D35_20161210SP17@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP17";
beginfig(342);
draw_upscrap(1)(1,((-7.87,4.84)
 .. controls (-7.87,4.84) and (-5.35,2.68) .. (-4.01,0.60)
 .. controls (-2.66,-1.47) and (-0.59,-5.40) .. (0.92,-5.82)
 .. controls (2.42,-6.24) and (3.90,-7.74) .. (3.90,-7.74)
),
1,((7.87,-3.82)
 .. controls (7.87,-3.82) and (6.63,-2.74) .. (6.05,-1.40)
 .. controls (5.46,-0.05) and (5.02,0.79) .. (4.08,1.45)
 .. controls (3.13,2.10) and (-1.16,5.91) .. (-4.19,7.74)
));
draw_downscrap;
endfig;
beginfig(343);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((7.87,-3.82)
 .. controls (7.87,-3.82) and (6.63,-2.74) .. (6.05,-1.40)
 .. controls (5.46,-0.05) and (5.02,0.79) .. (4.08,1.45)
 .. controls (3.13,2.10) and (-1.16,5.91) .. (-4.19,7.74)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.87,4.84)
 .. controls (-7.87,4.84) and (-5.35,2.68) .. (-4.01,0.60)
 .. controls (-2.66,-1.47) and (-0.59,-5.40) .. (0.92,-5.82)
 .. controls (2.42,-6.24) and (3.90,-7.74) .. (3.90,-7.74)
));
endfig;
background:=(0.25000,0.76000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.76000, 1.00000);
current_scrap := "D35_20161210SP16@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP16";
beginfig(344);
draw_upscrap(1)(1,((-41.73,38.74)
 .. controls (-41.57,38.42) and (-38.07,36.87) .. (-36.97,35.12)
 .. controls (-35.87,33.38) and (-36.18,31.50) .. (-34.64,30.90)
 .. controls (-33.10,30.30) and (-31.70,29.71) .. (-28.59,30.40)
 .. controls (-25.47,31.08) and (-22.40,31.86) .. (-21.72,25.91)
 .. controls (-21.05,19.95) and (-23.15,21.00) .. (-24.25,19.41)
 .. controls (-25.35,17.81) and (-24.64,17.63) .. (-23.39,15.51)
 .. controls (-22.14,13.40) and (-18.85,8.03) .. (-18.94,6.82)
 .. controls (-19.02,5.60) and (-17.05,3.44) .. (-16.19,0.27)
 .. controls (-15.32,-2.91) and (-14.09,-2.76) .. (-11.60,-4.60)
 .. controls (-9.11,-6.45) and (-6.03,-5.58) .. (-3.54,-7.37)
 .. controls (-1.05,-9.17) and (6.88,-12.01) .. (6.57,-18.35)
 .. controls (6.27,-24.69) and (4.93,-24.55) .. (4.27,-26.99)
 .. controls (3.60,-29.42) and (1.01,-32.94) .. (1.12,-34.71)
 .. controls (1.22,-36.48) and (0.74,-37.57) .. (1.38,-38.74)
),
1,reverse ((-45.69,34.82)
 .. controls (-45.01,34.23) and (-42.53,31.58) .. (-42.04,30.87)
 .. controls (-41.55,30.16) and (-34.34,24.21) .. (-33.33,23.69)
 .. controls (-32.33,23.17) and (-33.43,21.66) .. (-32.62,20.25)
 .. controls (-31.82,18.85) and (-31.07,15.91) .. (-29.53,15.44)
 .. controls (-27.98,14.97) and (-26.45,11.03) .. (-25.97,9.42)
 .. controls (-25.50,7.81) and (-23.20,4.49) .. (-22.81,3.02)
 .. controls (-22.41,1.55) and (-21.43,-1.18) .. (-21.67,-2.78)
 .. controls (-21.92,-4.39) and (-18.89,-12.18) .. (-18.62,-14.14)
 .. controls (-18.35,-16.09) and (-15.60,-20.75) .. (-15.21,-23.62)
 .. controls (-14.82,-26.49) and (-13.81,-28.13) .. (-13.24,-29.71)
 .. controls (-12.67,-31.28) and (-8.93,-35.91) .. (-8.93,-35.91)
));
draw_downscrap;
endfig;
beginfig(345);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-45.69,34.82)
 .. controls (-45.01,34.23) and (-42.53,31.58) .. (-42.04,30.87)
 .. controls (-41.55,30.16) and (-34.34,24.21) .. (-33.33,23.69)
 .. controls (-32.33,23.17) and (-33.43,21.66) .. (-32.62,20.25)
 .. controls (-31.82,18.85) and (-31.07,15.91) .. (-29.53,15.44)
 .. controls (-27.98,14.97) and (-26.45,11.03) .. (-25.97,9.42)
 .. controls (-25.50,7.81) and (-23.20,4.49) .. (-22.81,3.02)
 .. controls (-22.41,1.55) and (-21.43,-1.18) .. (-21.67,-2.78)
 .. controls (-21.92,-4.39) and (-18.89,-12.18) .. (-18.62,-14.14)
 .. controls (-18.35,-16.09) and (-15.60,-20.75) .. (-15.21,-23.62)
 .. controls (-14.82,-26.49) and (-13.81,-28.13) .. (-13.24,-29.71)
 .. controls (-12.67,-31.28) and (-8.93,-35.91) .. (-8.93,-35.91)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-41.73,38.74)
 .. controls (-41.57,38.42) and (-38.07,36.87) .. (-36.97,35.12)
 .. controls (-35.87,33.38) and (-36.18,31.50) .. (-34.64,30.90)
 .. controls (-33.10,30.30) and (-31.70,29.71) .. (-28.59,30.40)
 .. controls (-25.47,31.08) and (-22.40,31.86) .. (-21.72,25.91)
 .. controls (-21.05,19.95) and (-23.15,21.00) .. (-24.25,19.41)
 .. controls (-25.35,17.81) and (-24.64,17.63) .. (-23.39,15.51)
 .. controls (-22.14,13.40) and (-18.85,8.03) .. (-18.94,6.82)
 .. controls (-19.02,5.60) and (-17.05,3.44) .. (-16.19,0.27)
 .. controls (-15.32,-2.91) and (-14.09,-2.76) .. (-11.60,-4.60)
 .. controls (-9.11,-6.45) and (-6.03,-5.58) .. (-3.54,-7.37)
 .. controls (-1.05,-9.17) and (6.88,-12.01) .. (6.57,-18.35)
 .. controls (6.27,-24.69) and (4.93,-24.55) .. (4.27,-26.99)
 .. controls (3.60,-29.42) and (1.01,-32.94) .. (1.12,-34.71)
 .. controls (1.22,-36.48) and (0.74,-37.57) .. (1.38,-38.74)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((10.14,-15.08)
 -- (42.37,-17.30)
));
endfig;
beginfig(346);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char82 \char58 \ \char43 \char51 \char48 \char109 \mainfont{} etex,(45.69,-17.53),0.0,0);
endfig;
background:=(0.25000,0.48250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.48250, 1.00000);
current_scrap := "D35_20161210SP2@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP2";
beginfig(347);
draw_upscrap(1)(1,((-50.28,42.44)
 .. controls (-50.28,42.44) and (-44.17,34.76) .. (-43.53,33.63)
 .. controls (-42.89,32.50) and (-38.45,28.86) .. (-37.19,26.06)
 .. controls (-35.94,23.27) and (-34.48,19.70) .. (-34.01,18.63)
 .. controls (-33.54,17.56) and (-31.43,11.46) .. (-27.07,7.33)
 .. controls (-22.71,3.19) and (-22.19,-0.41) .. (-21.15,-2.28)
 .. controls (-20.10,-4.16) and (-17.04,-10.15) .. (-15.98,-11.12)
 .. controls (-14.92,-12.10) and (-12.82,-12.42) .. (-12.01,-11.75)
 .. controls (-11.20,-11.09) and (-10.13,-11.93) .. (-9.45,-13.15)
 .. controls (-8.76,-14.37) and (-8.52,-16.06) .. (-7.85,-16.87)
 .. controls (-7.19,-17.68) and (-6.81,-18.70) .. (-6.23,-19.46)
 .. controls (-5.65,-20.22) and (-2.86,-24.29) .. (-1.97,-26.34)
 .. controls (-1.07,-28.39) and (-0.86,-30.57) .. (1.16,-32.06)
 .. controls (3.18,-33.55) and (4.01,-35.23) .. (4.64,-36.49)
 .. controls (5.28,-37.75) and (5.49,-38.63) .. (6.91,-38.86)
 .. controls (8.34,-39.09) and (8.77,-40.66) .. (9.14,-41.18)
 .. controls (9.51,-41.70) and (9.73,-42.44) .. (9.73,-42.44)
),
1,((13.62,-41.08)
 .. controls (13.62,-41.08) and (11.03,-38.06) .. (10.78,-37.10)
 .. controls (10.53,-36.13) and (9.22,-32.93) .. (9.11,-31.84)
 .. controls (9.01,-30.75) and (8.35,-30.48) .. (8.43,-29.36)
 .. controls (8.50,-28.23) and (7.40,-26.62) .. (10.70,-25.23)
 .. controls (13.99,-23.83) and (16.65,-23.88) .. (16.62,-21.13)
 .. controls (16.58,-18.37) and (15.36,-17.16) .. (10.20,-18.07)
 .. controls (5.04,-18.97) and (2.42,-19.65) .. (0.17,-18.95)
 .. controls (-2.09,-18.26) and (-2.90,-17.62) .. (-4.29,-15.58)
 .. controls (-5.68,-13.54) and (-7.20,-9.33) .. (-7.10,-7.90)
 .. controls (-7.00,-6.46) and (-3.65,-3.04) .. (-7.63,-3.08)
 .. controls (-11.60,-3.12) and (-13.25,-4.14) .. (-14.43,-2.97)
 .. controls (-15.61,-1.81) and (-20.55,4.40) .. (-21.21,5.39)
 .. controls (-21.86,6.38) and (-23.41,11.40) .. (-25.12,14.09)
 .. controls (-26.83,16.78) and (-29.45,17.32) .. (-30.69,19.62)
 .. controls (-31.93,21.91) and (-31.82,24.25) .. (-32.20,25.90)
 .. controls (-32.58,27.55) and (-34.50,31.07) .. (-35.55,32.94)
 .. controls (-36.59,34.82) and (-40.07,38.71) .. (-41.03,40.40)
));
draw_downscrap;
endfig;
beginfig(348);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((13.62,-41.08)
 .. controls (13.62,-41.08) and (11.03,-38.06) .. (10.78,-37.10)
 .. controls (10.53,-36.13) and (9.22,-32.93) .. (9.11,-31.84)
 .. controls (9.01,-30.75) and (8.35,-30.48) .. (8.43,-29.36)
 .. controls (8.50,-28.23) and (7.40,-26.62) .. (10.70,-25.23)
 .. controls (13.99,-23.83) and (16.65,-23.88) .. (16.62,-21.13)
 .. controls (16.58,-18.37) and (15.36,-17.16) .. (10.20,-18.07)
 .. controls (5.04,-18.97) and (2.42,-19.65) .. (0.17,-18.95)
 .. controls (-2.09,-18.26) and (-2.90,-17.62) .. (-4.29,-15.58)
 .. controls (-5.68,-13.54) and (-7.20,-9.33) .. (-7.10,-7.90)
 .. controls (-7.00,-6.46) and (-3.65,-3.04) .. (-7.63,-3.08)
 .. controls (-11.60,-3.12) and (-13.25,-4.14) .. (-14.43,-2.97)
 .. controls (-15.61,-1.81) and (-20.55,4.40) .. (-21.21,5.39)
 .. controls (-21.86,6.38) and (-23.41,11.40) .. (-25.12,14.09)
 .. controls (-26.83,16.78) and (-29.45,17.32) .. (-30.69,19.62)
 .. controls (-31.93,21.91) and (-31.82,24.25) .. (-32.20,25.90)
 .. controls (-32.58,27.55) and (-34.50,31.07) .. (-35.55,32.94)
 .. controls (-36.59,34.82) and (-40.07,38.71) .. (-41.03,40.40)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((20.85,-20.56)
 -- (45.72,-22.27)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-11.14,-16.10)
 -- (-29.76,-32.32)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-11.37,0.16)
 -- (5.42,14.79)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-50.28,42.44)
 .. controls (-50.28,42.44) and (-44.17,34.76) .. (-43.53,33.63)
 .. controls (-42.89,32.50) and (-38.45,28.86) .. (-37.19,26.06)
 .. controls (-35.94,23.27) and (-34.48,19.70) .. (-34.01,18.63)
 .. controls (-33.54,17.56) and (-31.43,11.46) .. (-27.07,7.33)
 .. controls (-22.71,3.19) and (-22.19,-0.41) .. (-21.15,-2.28)
 .. controls (-20.10,-4.16) and (-17.04,-10.15) .. (-15.98,-11.12)
 .. controls (-14.92,-12.10) and (-12.82,-12.42) .. (-12.01,-11.75)
 .. controls (-11.20,-11.09) and (-10.13,-11.93) .. (-9.45,-13.15)
 .. controls (-8.76,-14.37) and (-8.52,-16.06) .. (-7.85,-16.87)
 .. controls (-7.19,-17.68) and (-6.81,-18.70) .. (-6.23,-19.46)
 .. controls (-5.65,-20.22) and (-2.86,-24.29) .. (-1.97,-26.34)
 .. controls (-1.07,-28.39) and (-0.86,-30.57) .. (1.16,-32.06)
 .. controls (3.18,-33.55) and (4.01,-35.23) .. (4.64,-36.49)
 .. controls (5.28,-37.75) and (5.49,-38.63) .. (6.91,-38.86)
 .. controls (8.34,-39.09) and (8.77,-40.66) .. (9.14,-41.18)
 .. controls (9.51,-41.70) and (9.73,-42.44) .. (9.73,-42.44)
));
endfig;
beginfig(349);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char82 \char58 \char43 \char49 \char56 \char109 \mainfont{} etex,(50.28,-22.95),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char82 \char50 \mainfont{} etex,(-33.00,-34.89),0.0,0);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char82 \char111 \char99 \char104 \char101 \ \char102 \char114 \char97 \char99 \char116 \char117 \char114 \thfc\char233 \thfb\char101 \ \thfc\char233 \thfb\char98 \char111 \char117 \char108 \char101 \char117 \char115 \char101 \mainfont{} etex,(8.64,16.91),0.0,0);
endfig;
background:=(0.25000,0.45250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.45250, 1.00000);
current_scrap := "D35_20161210SP1@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP1";
beginfig(350);
draw_upscrap(1)(1,((-15.34,20.32)
 .. controls (-14.86,19.13) and (-10.84,12.48) .. (-10.42,10.98)
 .. controls (-10.02,9.60) and (-9.78,5.44) .. (-9.38,3.86)
 .. controls (-8.86,1.80) and (-6.70,-0.29) .. (-6.70,-0.29)
),
1,((-3.14,1.92)
 .. controls (-3.14,1.92) and (-5.93,3.42) .. (-5.92,6.23)
 .. controls (-5.91,8.45) and (-7.04,10.30) .. (-7.34,11.99)
 .. controls (-7.66,13.83) and (-10.69,20.69) .. (-11.46,21.68)
));
draw_downscrap;
endfig;
beginfig(351);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.14,1.92)
 .. controls (-3.14,1.92) and (-5.93,3.42) .. (-5.92,6.23)
 .. controls (-5.91,8.45) and (-7.04,10.30) .. (-7.34,11.99)
 .. controls (-7.66,13.83) and (-10.69,20.69) .. (-11.46,21.68)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-15.34,20.32)
 .. controls (-14.86,19.13) and (-10.84,12.48) .. (-10.42,10.98)
 .. controls (-10.02,9.60) and (-9.78,5.44) .. (-9.38,3.86)
 .. controls (-8.86,1.80) and (-6.70,-0.29) .. (-6.70,-0.29)
));
endfig;
background:=(0.25000,0.73750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.73750, 1.00000);
current_scrap := "D35_20161210SP15@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP15";
beginfig(352);
draw_upscrap(1)(1,((6.95,14.03)
 .. controls (6.95,14.03) and (1.94,17.94) .. (0.82,19.91)
 .. controls (-0.31,21.88) and (-3.11,29.07) .. (-4.26,30.09)
 .. controls (-5.40,31.12) and (-7.95,35.40) .. (-8.19,35.82)
 .. controls (-8.43,36.24) and (-15.83,48.07) .. (-17.04,49.47)
),
1,reverse ((12.93,17.68)
 .. controls (12.93,17.68) and (8.89,22.46) .. (8.21,23.19)
 .. controls (7.54,23.91) and (-0.40,37.00) .. (-0.83,37.84)
 .. controls (-1.27,38.68) and (-6.13,45.42) .. (-6.72,46.64)
));
draw_downscrap;
endfig;
beginfig(353);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((12.93,17.68)
 .. controls (12.93,17.68) and (8.89,22.46) .. (8.21,23.19)
 .. controls (7.54,23.91) and (-0.40,37.00) .. (-0.83,37.84)
 .. controls (-1.27,38.68) and (-6.13,45.42) .. (-6.72,46.64)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.95,14.03)
 .. controls (6.95,14.03) and (1.94,17.94) .. (0.82,19.91)
 .. controls (-0.31,21.88) and (-3.11,29.07) .. (-4.26,30.09)
 .. controls (-5.40,31.12) and (-7.95,35.40) .. (-8.19,35.82)
 .. controls (-8.43,36.24) and (-15.83,48.07) .. (-17.04,49.47)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-2.30,45.43)
 -- (13.15,44.36)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-38.61,55.24)
 -- (-40.22,54.09)
 -- (38.13,-55.24)
 -- (40.22,-53.67)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-4.90,5.01)
 -- (-13.81,-2.58)
));
endfig;
beginfig(354);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char69 \char54 \mainfont{} etex,(16.47,44.22),0.0,0);
drawoptions();
p_label.ulft(btex \thlabel\thnormalsize \thfb\char80 \char114 \thfc\char233 \thfb\char115 \char101 \char110 \char99 \char101 \ \char103 \char97 \char108 \char101 \char114 \char105 \char101 \ \char102 \char111 \char115 \char115 \char105 \char108 \char101 \mainfont{} etex,(-16.85,-4.72),0.0,0);
endfig;
background:=(0.25000,0.72250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.72250, 1.00000);
current_scrap := "D35_20161210SP14@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP14";
beginfig(355);
draw_upscrap(1)(1,((14.66,-19.84)
 .. controls (14.66,-19.84) and (13.87,-18.20) .. (12.89,-16.06)
 .. controls (11.91,-13.92) and (9.82,-12.15) .. (8.61,-7.51)
 .. controls (7.39,-2.87) and (4.24,-0.22) .. (2.66,2.37)
 .. controls (1.08,4.96) and (-0.50,7.69) .. (-0.66,10.58)
 .. controls (-0.82,13.48) and (-5.30,14.60) .. (-5.93,15.23)
 .. controls (-6.56,15.86) and (-8.68,19.84) .. (-8.68,19.84)
),
1,reverse ((7.34,-19.38)
 .. controls (7.34,-19.38) and (4.34,-17.77) .. (4.30,-15.07)
 .. controls (4.26,-12.36) and (4.60,-8.68) .. (4.25,-7.21)
 .. controls (3.90,-5.75) and (4.15,-4.81) .. (3.73,-4.29)
 .. controls (3.32,-3.77) and (-1.68,2.26) .. (-3.96,3.95)
 .. controls (-6.23,5.64) and (-6.17,5.78) .. (-5.89,8.01)
 .. controls (-5.60,10.25) and (-6.03,11.76) .. (-7.73,12.60)
 .. controls (-9.44,13.44) and (-13.26,15.46) .. (-14.66,16.19)
));
draw_downscrap;
endfig;
beginfig(356);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((7.34,-19.38)
 .. controls (7.34,-19.38) and (4.34,-17.77) .. (4.30,-15.07)
 .. controls (4.26,-12.36) and (4.60,-8.68) .. (4.25,-7.21)
 .. controls (3.90,-5.75) and (4.15,-4.81) .. (3.73,-4.29)
 .. controls (3.32,-3.77) and (-1.68,2.26) .. (-3.96,3.95)
 .. controls (-6.23,5.64) and (-6.17,5.78) .. (-5.89,8.01)
 .. controls (-5.60,10.25) and (-6.03,11.76) .. (-7.73,12.60)
 .. controls (-9.44,13.44) and (-13.26,15.46) .. (-14.66,16.19)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((14.66,-19.84)
 .. controls (14.66,-19.84) and (13.87,-18.20) .. (12.89,-16.06)
 .. controls (11.91,-13.92) and (9.82,-12.15) .. (8.61,-7.51)
 .. controls (7.39,-2.87) and (4.24,-0.22) .. (2.66,2.37)
 .. controls (1.08,4.96) and (-0.50,7.69) .. (-0.66,10.58)
 .. controls (-0.82,13.48) and (-5.30,14.60) .. (-5.93,15.23)
 .. controls (-6.56,15.86) and (-8.68,19.84) .. (-8.68,19.84)
));
endfig;
background:=(0.25000,0.70750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.70750, 1.00000);
current_scrap := "D35_20161210SP13@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP13";
beginfig(357);
draw_upscrap(1)(1,((-11.89,10.47)
 .. controls (-9.58,8.55) and (-2.97,0.38) .. (-0.84,-2.02)
 .. controls (1.30,-4.43) and (2.04,-4.51) .. (2.12,-6.45)
 .. controls (2.19,-8.41) and (6.81,-10.47) .. (6.81,-10.47)
),
1,((11.89,-6.91)
 .. controls (11.89,-6.91) and (11.04,-4.24) .. (10.28,-3.39)
 .. controls (9.52,-2.54) and (7.82,-1.78) .. (6.68,-1.30)
 .. controls (5.54,-0.82) and (3.07,-0.10) .. (2.11,1.01)
 .. controls (1.15,2.11) and (-3.27,7.21) .. (-4.56,10.01)
));
draw_downscrap;
endfig;
beginfig(358);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((11.89,-6.91)
 .. controls (11.89,-6.91) and (11.04,-4.24) .. (10.28,-3.39)
 .. controls (9.52,-2.54) and (7.82,-1.78) .. (6.68,-1.30)
 .. controls (5.54,-0.82) and (3.07,-0.10) .. (2.11,1.01)
 .. controls (1.15,2.11) and (-3.27,7.21) .. (-4.56,10.01)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-11.89,10.47)
 .. controls (-9.58,8.55) and (-2.97,0.38) .. (-0.84,-2.02)
 .. controls (1.30,-4.43) and (2.04,-4.51) .. (2.12,-6.45)
 .. controls (2.19,-8.41) and (6.81,-10.47) .. (6.81,-10.47)
));
endfig;
background:=(0.25000,0.70000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.70000, 1.00000);
current_scrap := "D35_20161210SP12@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP12";
beginfig(359);
draw_upscrap(1)(1,((-3.05,10.76)
 .. controls (-3.05,10.76) and (-1.82,9.71) .. (0.44,7.48)
 .. controls (2.67,5.29) and (4.09,4.16) .. (5.23,3.96)
 .. controls (8.25,3.43) and (8.61,2.44) .. (8.61,2.44)
),
1,((10.01,10.99)
 .. controls (10.01,10.99) and (8.35,9.98) .. (7.68,10.22)
 .. controls (7.01,10.47) and (5.24,10.68) .. (4.78,11.34)
 .. controls (4.32,12.00) and (2.74,13.03) .. (2.03,14.32)
),
0,((2.03,14.32)
 .. controls (2.03,14.32) and (-3.38,14.71) .. (-3.05,10.76)
));
draw_downscrap;
endfig;
beginfig(360);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-3.05,10.76)
 .. controls (-3.05,10.76) and (-1.82,9.71) .. (0.44,7.48)
 .. controls (2.67,5.29) and (4.09,4.16) .. (5.23,3.96)
 .. controls (8.25,3.43) and (8.61,2.44) .. (8.61,2.44)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((6.85,1.90)
 -- (-6.77,-11.93)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((10.01,10.99)
 .. controls (10.01,10.99) and (8.35,9.98) .. (7.68,10.22)
 .. controls (7.01,10.47) and (5.24,10.68) .. (4.78,11.34)
 .. controls (4.32,12.00) and (2.74,13.03) .. (2.03,14.32)
));
endfig;
beginfig(361);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char67 \char49 \char48 \ \mainfont{} etex,(-10.01,-14.71),0.0,0);
endfig;
background:=(0.25000,0.64750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.64750, 1.00000);
current_scrap := "D35_20161210SP11@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP11";
beginfig(362);
draw_upscrap(1)(1,((-2.38,-22.71)
 .. controls (-2.38,-22.71) and (-2.46,-19.19) .. (-2.99,-17.60)
 .. controls (-3.56,-15.95) and (-5.10,-9.26) .. (-5.26,-8.75)
 .. controls (-5.42,-8.24) and (-5.69,-5.47) .. (-5.21,-5.34)
 .. controls (-4.72,-5.21) and (-2.79,-5.38) .. (-1.54,-4.98)
 .. controls (-0.30,-4.58) and (3.19,-2.17) .. (-0.69,3.81)
 .. controls (-4.56,9.79) and (-5.64,8.26) .. (-7.88,7.53)
 .. controls (-10.11,6.80) and (-11.60,5.92) .. (-12.25,5.49)
 .. controls (-12.90,5.05) and (-15.93,3.79) .. (-16.06,3.61)
 .. controls (-16.19,3.43) and (-17.92,1.74) .. (-17.92,1.74)
),
0,((-17.92,1.74)
 .. controls (-17.92,1.74) and (-20.23,-2.75) .. (-19.32,-6.81)
),
1,((-19.32,-6.81)
 .. controls (-19.32,-6.81) and (-18.23,-11.61) .. (-17.91,-12.98)
),
1,((-17.91,-12.98)
 .. controls (-17.91,-12.98) and (-17.97,-14.83) .. (-16.88,-16.72)
 .. controls (-15.80,-18.61) and (-16.26,-19.48) .. (-15.28,-20.81)
 .. controls (-14.30,-22.14) and (-13.85,-23.30) .. (-13.85,-23.30)
));
draw_downscrap;
endfig;
beginfig(363);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2.38,-22.71)
 .. controls (-2.38,-22.71) and (-2.46,-19.19) .. (-2.99,-17.60)
 .. controls (-3.56,-15.95) and (-5.10,-9.26) .. (-5.26,-8.75)
 .. controls (-5.42,-8.24) and (-5.69,-5.47) .. (-5.21,-5.34)
 .. controls (-4.72,-5.21) and (-2.79,-5.38) .. (-1.54,-4.98)
 .. controls (-0.30,-4.58) and (3.19,-2.17) .. (-0.69,3.81)
 .. controls (-4.56,9.79) and (-5.64,8.26) .. (-7.88,7.53)
 .. controls (-10.11,6.80) and (-11.60,5.92) .. (-12.25,5.49)
 .. controls (-12.90,5.05) and (-15.93,3.79) .. (-16.06,3.61)
 .. controls (-16.19,3.43) and (-17.92,1.74) .. (-17.92,1.74)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((3.19,6.31)
 -- (17.44,20.60)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-19.32,-6.81)
 .. controls (-19.32,-6.81) and (-18.23,-11.61) .. (-17.91,-12.98)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-17.91,-12.98)
 .. controls (-17.91,-12.98) and (-17.97,-14.83) .. (-16.88,-16.72)
 .. controls (-15.80,-18.61) and (-16.26,-19.48) .. (-15.28,-20.81)
 .. controls (-14.30,-22.14) and (-13.85,-23.30) .. (-13.85,-23.30)
));
endfig;
beginfig(364);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char80 \char82 \char58 \ \char43 \char63 \mainfont{} etex,(20.23,23.30),0.0,0);
endfig;
background:=(0.25000,0.64000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.64000, 1.00000);
current_scrap := "D35_20161210SP10@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP10";
beginfig(365);
draw_upscrap(1)(1,((-24.93,9.69)
 .. controls (-24.93,9.69) and (-24.22,7.81) .. (-24.06,5.94)
 .. controls (-23.91,4.08) and (-23.92,1.82) .. (-24.12,0.71)
 .. controls (-24.32,-0.40) and (-26.82,-10.28) .. (-26.82,-10.28)
),
1,((-16.53,-9.28)
 .. controls (-16.53,-9.28) and (-16.08,-3.20) .. (-15.29,-0.70)
 .. controls (-14.50,1.81) and (-13.26,8.39) .. (-13.46,10.28)
));
draw_downscrap;
endfig;
beginfig(366);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-16.53,-9.28)
 .. controls (-16.53,-9.28) and (-16.08,-3.20) .. (-15.29,-0.70)
 .. controls (-14.50,1.81) and (-13.26,8.39) .. (-13.46,10.28)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-12.06,2.60)
 -- (22.95,2.62)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-24.93,9.69)
 .. controls (-24.93,9.69) and (-24.22,7.81) .. (-24.06,5.94)
 .. controls (-23.91,4.08) and (-23.92,1.82) .. (-24.12,0.71)
 .. controls (-24.32,-0.40) and (-26.82,-10.28) .. (-26.82,-10.28)
));
endfig;
beginfig(367);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char80 \char82 \char58 \ \char43 \char63 \mainfont{} etex,(26.82,2.62),0.0,0);
endfig;
background:=(0.25000,0.62500,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.62500, 1.00000);
current_scrap := "D35_20161210SP9@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP9";
beginfig(368);
draw_upscrap(1)(1,((-15.70,41.68)
 .. controls (-15.70,41.68) and (-17.88,37.41) .. (-15.55,32.97)
 .. controls (-13.16,28.44) and (-10.80,23.28) .. (-9.55,20.49)
 .. controls (-8.31,17.70) and (-5.32,12.45) .. (-4.72,10.79)
 .. controls (-4.12,9.12) and (-2.30,4.85) .. (0.49,2.76)
 .. controls (3.28,0.68) and (6.54,1.49) .. (9.80,-2.30)
 .. controls (13.06,-6.09) and (14.84,-8.24) .. (15.17,-10.79)
 .. controls (15.49,-13.34) and (15.89,-15.98) .. (14.56,-18.96)
 .. controls (13.23,-21.93) and (10.50,-28.83) .. (10.50,-28.83)
),
1,((17.31,-29.48)
 .. controls (17.31,-29.48) and (21.69,-20.89) .. (23.33,-18.03)
 .. controls (24.97,-15.16) and (25.19,-14.59) .. (26.43,-12.24)
 .. controls (27.67,-9.89) and (28.78,-8.25) .. (29.90,-7.74)
),
1,((29.42,-1.57)
 .. controls (29.42,-1.57) and (23.12,1.84) .. (21.01,4.64)
 .. controls (18.91,7.45) and (17.97,17.84) .. (12.62,14.24)
 .. controls (7.27,10.64) and (7.72,8.08) .. (5.45,9.82)
 .. controls (3.18,11.55) and (2.49,13.22) .. (1.89,14.93)
 .. controls (1.29,16.64) and (0.81,21.05) .. (-0.55,24.17)
 .. controls (-1.90,27.28) and (-4.17,34.18) .. (-4.93,36.05)
 .. controls (-5.69,37.92) and (-5.46,41.82) .. (-5.40,42.67)
));
draw_downscrap;
endfig;
beginfig(369);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((29.42,-1.57)
 .. controls (29.42,-1.57) and (23.12,1.84) .. (21.01,4.64)
 .. controls (18.91,7.45) and (17.97,17.84) .. (12.62,14.24)
 .. controls (7.27,10.64) and (7.72,8.08) .. (5.45,9.82)
 .. controls (3.18,11.55) and (2.49,13.22) .. (1.89,14.93)
 .. controls (1.29,16.64) and (0.81,21.05) .. (-0.55,24.17)
 .. controls (-1.90,27.28) and (-4.17,34.18) .. (-4.93,36.05)
 .. controls (-5.69,37.92) and (-5.46,41.82) .. (-5.40,42.67)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-15.70,41.68)
 .. controls (-15.70,41.68) and (-17.88,37.41) .. (-15.55,32.97)
 .. controls (-13.16,28.44) and (-10.80,23.28) .. (-9.55,20.49)
 .. controls (-8.31,17.70) and (-5.32,12.45) .. (-4.72,10.79)
 .. controls (-4.12,9.12) and (-2.30,4.85) .. (0.49,2.76)
 .. controls (3.28,0.68) and (6.54,1.49) .. (9.80,-2.30)
 .. controls (13.06,-6.09) and (14.84,-8.24) .. (15.17,-10.79)
 .. controls (15.49,-13.34) and (15.89,-15.98) .. (14.56,-18.96)
 .. controls (13.23,-21.93) and (10.50,-28.83) .. (10.50,-28.83)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-18.89,42.16)
 -- (-26.83,42.79)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((17.31,-29.48)
 .. controls (17.31,-29.48) and (21.69,-20.89) .. (23.33,-18.03)
 .. controls (24.97,-15.16) and (25.19,-14.59) .. (26.43,-12.24)
 .. controls (27.67,-9.89) and (28.78,-8.25) .. (29.90,-7.74)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((12.58,-32.71)
 -- (1.05,-43.02)
 -- (-19.23,-41.62)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((9.81,-24.40)
 -- (-18.18,-22.48)
));
endfig;
beginfig(370);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char82 \char52 \mainfont{} etex,(-29.90,43.02),0.0,0);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char49 \char48 \char48 \ \char109 \ \char101 \char120 \char112 \char108 \char111 \char114 \thfc\char233 \thfb\char58 \ \char97 \char114 \char114 \accent94 \char101 \char116 \ \char115 \char117 \char114 \ \char115 \char105 \char112 \char104 \char111 \char110 \mainfont{} etex,(-22.20,-41.51),0.0,0);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char49 \ \char108 \char112 \char115 \ \char49 \char48 \char47 \char49 \char50 \char47 \char50 \char48 \char49 \char54 \mainfont{} etex,(-20.78,-22.30),0.0,0);
endfig;
background:=(0.25000,0.61000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.61000, 1.00000);
current_scrap := "D35_20161210SP8@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP8";
beginfig(371);
draw_upscrap(1)(1,((13.84,-6.59)
 .. controls (13.84,-6.59) and (11.44,-4.46) .. (10.96,-3.77)
 .. controls (10.48,-3.07) and (7.84,-0.91) .. (7.15,0.13)
 .. controls (6.47,1.17) and (2.63,5.20) .. (-0.75,7.64)
 .. controls (-4.14,10.09) and (-5.00,11.24) .. (-7.52,10.94)
 .. controls (-10.05,10.63) and (-13.84,10.54) .. (-13.84,10.54)
),
1,reverse ((6.48,-11.24)
 .. controls (6.48,-11.24) and (3.65,-7.34) .. (2.16,-5.66)
 .. controls (0.68,-3.98) and (-0.63,-1.84) .. (-1.64,-1.07)
 .. controls (-2.64,-0.30) and (-7.53,3.76) .. (-8.43,4.23)
 .. controls (-9.34,4.71) and (-11.91,5.89) .. (-13.36,4.37)
));
draw_downscrap;
endfig;
beginfig(372);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.48,-11.24)
 .. controls (6.48,-11.24) and (3.65,-7.34) .. (2.16,-5.66)
 .. controls (0.68,-3.98) and (-0.63,-1.84) .. (-1.64,-1.07)
 .. controls (-2.64,-0.30) and (-7.53,3.76) .. (-8.43,4.23)
 .. controls (-9.34,4.71) and (-11.91,5.89) .. (-13.36,4.37)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((13.84,-6.59)
 .. controls (13.84,-6.59) and (11.44,-4.46) .. (10.96,-3.77)
 .. controls (10.48,-3.07) and (7.84,-0.91) .. (7.15,0.13)
 .. controls (6.47,1.17) and (2.63,5.20) .. (-0.75,7.64)
 .. controls (-4.14,10.09) and (-5.00,11.24) .. (-7.52,10.94)
 .. controls (-10.05,10.63) and (-13.84,10.54) .. (-13.84,10.54)
));
endfig;
background:=(0.25000,0.60250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.60250, 1.00000);
current_scrap := "D35_20161210SP7@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP7";
beginfig(373);
draw_upscrap(1)(1,((13.05,-17.09)
 .. controls (13.05,-17.09) and (11.98,-13.05) .. (11.37,-10.66)
 .. controls (10.77,-8.29) and (9.68,-5.78) .. (8.83,-3.92)
 .. controls (7.97,-2.06) and (5.09,4.95) .. (4.54,6.58)
 .. controls (3.99,8.21) and (1.33,12.49) .. (0.27,13.64)
 .. controls (-0.79,14.79) and (-5.06,18.58) .. (-5.69,19.07)
),
1,((-13.05,14.42)
 .. controls (-13.05,14.42) and (-6.21,8.36) .. (-4.83,6.38)
 .. controls (-3.45,4.42) and (-2.45,3.96) .. (-1.09,0.51)
 .. controls (0.28,-2.94) and (3.91,-9.63) .. (4.54,-11.04)
 .. controls (5.16,-12.44) and (6.50,-15.37) .. (6.74,-16.17)
 .. controls (6.99,-16.97) and (7.77,-19.07) .. (7.77,-19.07)
));
draw_downscrap;
endfig;
beginfig(374);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((13.05,-17.09)
 .. controls (13.05,-17.09) and (11.98,-13.05) .. (11.37,-10.66)
 .. controls (10.77,-8.29) and (9.68,-5.78) .. (8.83,-3.92)
 .. controls (7.97,-2.06) and (5.09,4.95) .. (4.54,6.58)
 .. controls (3.99,8.21) and (1.33,12.49) .. (0.27,13.64)
 .. controls (-0.79,14.79) and (-5.06,18.58) .. (-5.69,19.07)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-13.05,14.42)
 .. controls (-13.05,14.42) and (-6.21,8.36) .. (-4.83,6.38)
 .. controls (-3.45,4.42) and (-2.45,3.96) .. (-1.09,0.51)
 .. controls (0.28,-2.94) and (3.91,-9.63) .. (4.54,-11.04)
 .. controls (5.16,-12.44) and (6.50,-15.37) .. (6.74,-16.17)
 .. controls (6.99,-16.97) and (7.77,-19.07) .. (7.77,-19.07)
));
endfig;
background:=(0.25000,0.58000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.58000, 1.00000);
current_scrap := "D35_20161210SP6@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP6";
beginfig(375);
draw_upscrap(1)(1,((6.62,-26.64)
 .. controls (6.62,-26.64) and (6.78,-23.81) .. (6.91,-21.84)
 .. controls (7.05,-19.86) and (6.93,-17.06) .. (6.50,-14.73)
 .. controls (6.08,-12.40) and (6.96,-12.01) .. (5.74,-8.90)
 .. controls (4.52,-5.80) and (3.11,2.79) .. (2.64,4.68)
 .. controls (2.16,6.57) and (-1.59,25.17) .. (-1.76,26.64)
),
1,((-7.05,24.66)
 .. controls (-7.03,23.77) and (-6.65,20.44) .. (-6.54,17.92)
 .. controls (-6.43,15.39) and (-5.37,4.83) .. (-4.96,1.55)
 .. controls (-4.55,-1.74) and (-3.09,-8.11) .. (-3.19,-9.55)
 .. controls (-3.30,-10.98) and (-3.25,-14.86) .. (-3.75,-17.63)
 .. controls (-4.26,-20.39) and (-4.86,-23.10) .. (-4.86,-23.10)
));
draw_downscrap;
endfig;
beginfig(376);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((6.62,-26.64)
 .. controls (6.62,-26.64) and (6.78,-23.81) .. (6.91,-21.84)
 .. controls (7.05,-19.86) and (6.93,-17.06) .. (6.50,-14.73)
 .. controls (6.08,-12.40) and (6.96,-12.01) .. (5.74,-8.90)
 .. controls (4.52,-5.80) and (3.11,2.79) .. (2.64,4.68)
 .. controls (2.16,6.57) and (-1.59,25.17) .. (-1.76,26.64)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.05,24.66)
 .. controls (-7.03,23.77) and (-6.65,20.44) .. (-6.54,17.92)
 .. controls (-6.43,15.39) and (-5.37,4.83) .. (-4.96,1.55)
 .. controls (-4.55,-1.74) and (-3.09,-8.11) .. (-3.19,-9.55)
 .. controls (-3.30,-10.98) and (-3.25,-14.86) .. (-3.75,-17.63)
 .. controls (-4.26,-20.39) and (-4.86,-23.10) .. (-4.86,-23.10)
));
endfig;
background:=(0.25000,0.55000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.55000, 1.00000);
current_scrap := "D35_20161210SP5@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP5";
beginfig(377);
draw_upscrap(1)(1,((8.30,21.48)
 .. controls (8.30,21.48) and (7.62,10.93) .. (7.59,9.22)
 .. controls (7.56,7.51) and (8.01,-8.90) .. (8.38,-12.08)
 .. controls (8.75,-15.27) and (9.71,-28.78) .. (11.94,-32.49)
 .. controls (14.16,-36.21) and (15.49,-43.75) .. (15.70,-47.87)
 .. controls (15.91,-51.98) and (15.81,-54.19) .. (18.37,-56.30)
 .. controls (19.52,-57.26) and (20.17,-58.32) .. (20.17,-58.32)
),
1,((28.76,-52.10)
 .. controls (28.76,-52.10) and (27.46,-52.69) .. (27.40,-50.34)
 .. controls (27.33,-47.99) and (28.11,-45.83) .. (27.56,-44.62)
 .. controls (27.02,-43.41) and (24.41,-35.47) .. (23.34,-33.87)
 .. controls (22.28,-32.26) and (21.41,-29.13) .. (20.57,-28.31)
 .. controls (19.72,-27.48) and (18.63,-19.20) .. (18.80,-16.64)
 .. controls (18.98,-14.08) and (20.61,-4.76) .. (19.85,-1.37)
 .. controls (19.09,2.02) and (19.71,15.01) .. (19.78,17.94)
));
draw_downscrap;
endfig;
beginfig(378);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((28.76,-52.10)
 .. controls (28.76,-52.10) and (27.46,-52.69) .. (27.40,-50.34)
 .. controls (27.33,-47.99) and (28.11,-45.83) .. (27.56,-44.62)
 .. controls (27.02,-43.41) and (24.41,-35.47) .. (23.34,-33.87)
 .. controls (22.28,-32.26) and (21.41,-29.13) .. (20.57,-28.31)
 .. controls (19.72,-27.48) and (18.63,-19.20) .. (18.80,-16.64)
 .. controls (18.98,-14.08) and (20.61,-4.76) .. (19.85,-1.37)
 .. controls (19.09,2.02) and (19.71,15.01) .. (19.78,17.94)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((3.91,55.98)
 -- (-24.10,57.91)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((8.30,21.48)
 .. controls (8.30,21.48) and (7.62,10.93) .. (7.59,9.22)
 .. controls (7.56,7.51) and (8.01,-8.90) .. (8.38,-12.08)
 .. controls (8.75,-15.27) and (9.71,-28.78) .. (11.94,-32.49)
 .. controls (14.16,-36.21) and (15.49,-43.75) .. (15.70,-47.87)
 .. controls (15.91,-51.98) and (15.81,-54.19) .. (18.37,-56.30)
 .. controls (19.52,-57.26) and (20.17,-58.32) .. (20.17,-58.32)
));
endfig;
beginfig(379);
drawoptions();
p_label.lft(btex \thlabel\thnormalsize \thfb\char50 \ \char108 \char112 \char115 \ \char49 \char48 \char47 \char49 \char50 \char47 \char50 \char48 \char49 \char54 \mainfont{} etex,(-28.76,58.32),0.0,0);
endfig;
background:=(0.25000,0.52000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.52000, 1.00000);
current_scrap := "D35_20161210SP3@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP3";
beginfig(380);
draw_upscrap(1)(1,((27.85,-58.23)
 .. controls (27.85,-58.23) and (25.34,-54.00) .. (23.45,-52.02)
 .. controls (21.55,-50.04) and (17.40,-43.48) .. (16.53,-41.08)
 .. controls (15.66,-38.67) and (14.84,-32.93) .. (14.76,-30.80)
 .. controls (14.68,-28.68) and (13.90,-16.45) .. (13.55,-14.93)
 .. controls (13.20,-13.42) and (11.65,-5.92) .. (11.64,-4.65)
 .. controls (11.64,-3.39) and (8.18,9.21) .. (7.24,12.61)
 .. controls (6.30,16.01) and (7.23,14.37) .. (6.15,17.11)
 .. controls (5.08,19.84) and (4.24,21.39) .. (3.94,23.03)
 .. controls (3.65,24.68) and (2.94,28.74) .. (2.09,30.83)
 .. controls (1.24,32.92) and (-0.80,36.67) .. (-1.93,39.27)
 .. controls (-3.06,41.87) and (-6.60,46.18) .. (-7.85,47.03)
),
1,((-7.85,47.03)
 .. controls (-7.85,47.03) and (-8.96,51.12) .. (-15.92,47.05)
),
0,((-15.92,47.05)
 .. controls (-15.92,47.05) and (-24.56,42.81) .. (-24.51,40.83)
),
1,((-24.51,40.83)
 .. controls (-24.51,40.83) and (-23.65,38.24) .. (-22.71,36.82)
 .. controls (-21.77,35.41) and (-19.54,31.15) .. (-19.19,30.36)
 .. controls (-18.84,29.56) and (-17.01,27.32) .. (-16.18,26.27)
 .. controls (-15.35,25.22) and (-9.77,23.08) .. (-6.61,22.45)
 .. controls (-3.45,21.83) and (-1.57,20.21) .. (-1.45,18.13)
 .. controls (-1.32,16.04) and (-0.81,14.34) .. (-0.21,12.49)
 .. controls (0.38,10.65) and (0.71,5.62) .. (1.13,2.48)
 .. controls (1.54,-0.66) and (2.44,-6.05) .. (2.84,-7.38)
 .. controls (3.24,-8.72) and (5.88,-17.56) .. (5.86,-19.14)
 .. controls (5.85,-20.72) and (7.09,-31.45) .. (7.57,-35.63)
 .. controls (8.05,-39.81) and (8.77,-43.74) .. (9.27,-45.04)
 .. controls (9.77,-46.34) and (9.95,-46.30) .. (10.97,-47.77)
 .. controls (12.00,-49.24) and (15.20,-52.62) .. (16.27,-53.46)
 .. controls (17.34,-54.30) and (18.60,-56.19) .. (18.60,-56.19)
));
draw_downscrap;
endfig;
beginfig(381);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((27.85,-58.23)
 .. controls (27.85,-58.23) and (25.34,-54.00) .. (23.45,-52.02)
 .. controls (21.55,-50.04) and (17.40,-43.48) .. (16.53,-41.08)
 .. controls (15.66,-38.67) and (14.84,-32.93) .. (14.76,-30.80)
 .. controls (14.68,-28.68) and (13.90,-16.45) .. (13.55,-14.93)
 .. controls (13.20,-13.42) and (11.65,-5.92) .. (11.64,-4.65)
 .. controls (11.64,-3.39) and (8.18,9.21) .. (7.24,12.61)
 .. controls (6.30,16.01) and (7.23,14.37) .. (6.15,17.11)
 .. controls (5.08,19.84) and (4.24,21.39) .. (3.94,23.03)
 .. controls (3.65,24.68) and (2.94,28.74) .. (2.09,30.83)
 .. controls (1.24,32.92) and (-0.80,36.67) .. (-1.93,39.27)
 .. controls (-3.06,41.87) and (-6.60,46.18) .. (-7.85,47.03)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((25.71,-46.67)
 -- (42.25,-31.84)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((25.31,56.29)
 -- (2.39,36.49)
));
ATTR__height := -1;
drawoptions();
l_rockedge(((-27.34,38.36)
 -- (-42.49,25.42)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-7.85,47.03)
 .. controls (-7.85,47.03) and (-8.96,51.12) .. (-15.92,47.05)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-24.51,40.83)
 .. controls (-24.51,40.83) and (-23.65,38.24) .. (-22.71,36.82)
 .. controls (-21.77,35.41) and (-19.54,31.15) .. (-19.19,30.36)
 .. controls (-18.84,29.56) and (-17.01,27.32) .. (-16.18,26.27)
 .. controls (-15.35,25.22) and (-9.77,23.08) .. (-6.61,22.45)
 .. controls (-3.45,21.83) and (-1.57,20.21) .. (-1.45,18.13)
 .. controls (-1.32,16.04) and (-0.81,14.34) .. (-0.21,12.49)
 .. controls (0.38,10.65) and (0.71,5.62) .. (1.13,2.48)
 .. controls (1.54,-0.66) and (2.44,-6.05) .. (2.84,-7.38)
 .. controls (3.24,-8.72) and (5.88,-17.56) .. (5.86,-19.14)
 .. controls (5.85,-20.72) and (7.09,-31.45) .. (7.57,-35.63)
 .. controls (8.05,-39.81) and (8.77,-43.74) .. (9.27,-45.04)
 .. controls (9.77,-46.34) and (9.95,-46.30) .. (10.97,-47.77)
 .. controls (12.00,-49.24) and (15.20,-52.62) .. (16.27,-53.46)
 .. controls (17.34,-54.30) and (18.60,-56.19) .. (18.60,-56.19)
));
endfig;
beginfig(382);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char80 \char108 \char117 \char105 \char101 \ \char103 \char111 \char117 \char116 \char116 \char101 \ \thfc\char184 \ \thfb\char103 \char111 \char117 \char116 \char116 \char101 \mainfont{} etex,(45.81,-29.92),0.0,0);
drawoptions();
p_label.urt(btex \thlabel\thnormalsize \thfb\char80 \char82 \char58 \ \char43 \char63 \mainfont{} etex,(27.34,58.23),0.0,0);
drawoptions();
p_label.llft(btex \thlabel\thnormalsize \thfb\char82 \char52 \mainfont{} etex,(-45.81,21.77),0.0,0);
endfig;
background:=(0.25000,0.73750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.73750, 1.00000);
current_scrap := "D35_20161210SP15@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP15";
beginfig(383);
draw_upscrap(1)(1,((6.95,14.03)
 .. controls (6.95,14.03) and (1.94,17.94) .. (0.82,19.91)
 .. controls (-0.31,21.88) and (-3.11,29.07) .. (-4.26,30.09)
 .. controls (-5.40,31.12) and (-7.95,35.40) .. (-8.19,35.82)
 .. controls (-8.43,36.24) and (-15.83,48.07) .. (-17.04,49.47)
),
1,reverse ((12.93,17.68)
 .. controls (12.93,17.68) and (8.89,22.46) .. (8.21,23.19)
 .. controls (7.54,23.91) and (-0.40,37.00) .. (-0.83,37.84)
 .. controls (-1.27,38.68) and (-6.13,45.42) .. (-6.72,46.64)
));
draw_downscrap;
endfig;
background:=(0.25000,0.72250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.72250, 1.00000);
current_scrap := "D35_20161210SP14@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP14";
beginfig(384);
draw_upscrap(1)(1,((14.66,-19.84)
 .. controls (14.66,-19.84) and (13.87,-18.20) .. (12.89,-16.06)
 .. controls (11.91,-13.92) and (9.82,-12.15) .. (8.61,-7.51)
 .. controls (7.39,-2.87) and (4.24,-0.22) .. (2.66,2.37)
 .. controls (1.08,4.96) and (-0.50,7.69) .. (-0.66,10.58)
 .. controls (-0.82,13.48) and (-5.30,14.60) .. (-5.93,15.23)
 .. controls (-6.56,15.86) and (-8.68,19.84) .. (-8.68,19.84)
),
1,reverse ((7.34,-19.38)
 .. controls (7.34,-19.38) and (4.34,-17.77) .. (4.30,-15.07)
 .. controls (4.26,-12.36) and (4.60,-8.68) .. (4.25,-7.21)
 .. controls (3.90,-5.75) and (4.15,-4.81) .. (3.73,-4.29)
 .. controls (3.32,-3.77) and (-1.68,2.26) .. (-3.96,3.95)
 .. controls (-6.23,5.64) and (-6.17,5.78) .. (-5.89,8.01)
 .. controls (-5.60,10.25) and (-6.03,11.76) .. (-7.73,12.60)
 .. controls (-9.44,13.44) and (-13.26,15.46) .. (-14.66,16.19)
));
draw_downscrap;
endfig;
background:=(0.25000,0.70750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.70750, 1.00000);
current_scrap := "D35_20161210SP13@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP13";
beginfig(385);
draw_upscrap(1)(1,((-11.89,10.47)
 .. controls (-9.58,8.55) and (-2.97,0.38) .. (-0.84,-2.02)
 .. controls (1.30,-4.43) and (2.04,-4.51) .. (2.12,-6.45)
 .. controls (2.19,-8.41) and (6.81,-10.47) .. (6.81,-10.47)
),
1,((11.89,-6.91)
 .. controls (11.89,-6.91) and (11.04,-4.24) .. (10.28,-3.39)
 .. controls (9.52,-2.54) and (7.82,-1.78) .. (6.68,-1.30)
 .. controls (5.54,-0.82) and (3.07,-0.10) .. (2.11,1.01)
 .. controls (1.15,2.11) and (-3.27,7.21) .. (-4.56,10.01)
));
draw_downscrap;
endfig;
background:=(0.25000,0.70000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.70000, 1.00000);
current_scrap := "D35_20161210SP12@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP12";
beginfig(386);
draw_upscrap(1)(1,((-3.05,10.76)
 .. controls (-3.05,10.76) and (-1.82,9.71) .. (0.44,7.48)
 .. controls (2.67,5.29) and (4.09,4.16) .. (5.23,3.96)
 .. controls (8.25,3.43) and (8.61,2.44) .. (8.61,2.44)
),
1,((10.01,10.99)
 .. controls (10.01,10.99) and (8.35,9.98) .. (7.68,10.22)
 .. controls (7.01,10.47) and (5.24,10.68) .. (4.78,11.34)
 .. controls (4.32,12.00) and (2.74,13.03) .. (2.03,14.32)
),
0,((2.03,14.32)
 .. controls (2.03,14.32) and (-3.38,14.71) .. (-3.05,10.76)
));
draw_downscrap;
endfig;
background:=(0.25000,0.64750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.64750, 1.00000);
current_scrap := "D35_20161210SP11@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP11";
beginfig(387);
draw_upscrap(1)(1,((-2.38,-22.71)
 .. controls (-2.38,-22.71) and (-2.46,-19.19) .. (-2.99,-17.60)
 .. controls (-3.56,-15.95) and (-5.10,-9.26) .. (-5.26,-8.75)
 .. controls (-5.42,-8.24) and (-5.69,-5.47) .. (-5.21,-5.34)
 .. controls (-4.72,-5.21) and (-2.79,-5.38) .. (-1.54,-4.98)
 .. controls (-0.30,-4.58) and (3.19,-2.17) .. (-0.69,3.81)
 .. controls (-4.56,9.79) and (-5.64,8.26) .. (-7.88,7.53)
 .. controls (-10.11,6.80) and (-11.60,5.92) .. (-12.25,5.49)
 .. controls (-12.90,5.05) and (-15.93,3.79) .. (-16.06,3.61)
 .. controls (-16.19,3.43) and (-17.92,1.74) .. (-17.92,1.74)
),
0,((-17.92,1.74)
 .. controls (-17.92,1.74) and (-20.23,-2.75) .. (-19.32,-6.81)
),
1,((-19.32,-6.81)
 .. controls (-19.32,-6.81) and (-18.23,-11.61) .. (-17.91,-12.98)
),
1,((-17.91,-12.98)
 .. controls (-17.91,-12.98) and (-17.97,-14.83) .. (-16.88,-16.72)
 .. controls (-15.80,-18.61) and (-16.26,-19.48) .. (-15.28,-20.81)
 .. controls (-14.30,-22.14) and (-13.85,-23.30) .. (-13.85,-23.30)
));
draw_downscrap;
endfig;
background:=(0.25000,0.64000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.64000, 1.00000);
current_scrap := "D35_20161210SP10@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP10";
beginfig(388);
draw_upscrap(1)(1,((-24.93,9.69)
 .. controls (-24.93,9.69) and (-24.22,7.81) .. (-24.06,5.94)
 .. controls (-23.91,4.08) and (-23.92,1.82) .. (-24.12,0.71)
 .. controls (-24.32,-0.40) and (-26.82,-10.28) .. (-26.82,-10.28)
),
1,((-16.53,-9.28)
 .. controls (-16.53,-9.28) and (-16.08,-3.20) .. (-15.29,-0.70)
 .. controls (-14.50,1.81) and (-13.26,8.39) .. (-13.46,10.28)
));
draw_downscrap;
endfig;
background:=(0.25000,0.62500,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.62500, 1.00000);
current_scrap := "D35_20161210SP9@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP9";
beginfig(389);
draw_upscrap(1)(1,((-15.70,41.68)
 .. controls (-15.70,41.68) and (-17.88,37.41) .. (-15.55,32.97)
 .. controls (-13.16,28.44) and (-10.80,23.28) .. (-9.55,20.49)
 .. controls (-8.31,17.70) and (-5.32,12.45) .. (-4.72,10.79)
 .. controls (-4.12,9.12) and (-2.30,4.85) .. (0.49,2.76)
 .. controls (3.28,0.68) and (6.54,1.49) .. (9.80,-2.30)
 .. controls (13.06,-6.09) and (14.84,-8.24) .. (15.17,-10.79)
 .. controls (15.49,-13.34) and (15.89,-15.98) .. (14.56,-18.96)
 .. controls (13.23,-21.93) and (10.50,-28.83) .. (10.50,-28.83)
),
1,((17.31,-29.48)
 .. controls (17.31,-29.48) and (21.69,-20.89) .. (23.33,-18.03)
 .. controls (24.97,-15.16) and (25.19,-14.59) .. (26.43,-12.24)
 .. controls (27.67,-9.89) and (28.78,-8.25) .. (29.90,-7.74)
),
1,((29.42,-1.57)
 .. controls (29.42,-1.57) and (23.12,1.84) .. (21.01,4.64)
 .. controls (18.91,7.45) and (17.97,17.84) .. (12.62,14.24)
 .. controls (7.27,10.64) and (7.72,8.08) .. (5.45,9.82)
 .. controls (3.18,11.55) and (2.49,13.22) .. (1.89,14.93)
 .. controls (1.29,16.64) and (0.81,21.05) .. (-0.55,24.17)
 .. controls (-1.90,27.28) and (-4.17,34.18) .. (-4.93,36.05)
 .. controls (-5.69,37.92) and (-5.46,41.82) .. (-5.40,42.67)
));
draw_downscrap;
endfig;
background:=(0.25000,0.61000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.61000, 1.00000);
current_scrap := "D35_20161210SP8@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP8";
beginfig(390);
draw_upscrap(1)(1,((13.84,-6.59)
 .. controls (13.84,-6.59) and (11.44,-4.46) .. (10.96,-3.77)
 .. controls (10.48,-3.07) and (7.84,-0.91) .. (7.15,0.13)
 .. controls (6.47,1.17) and (2.63,5.20) .. (-0.75,7.64)
 .. controls (-4.14,10.09) and (-5.00,11.24) .. (-7.52,10.94)
 .. controls (-10.05,10.63) and (-13.84,10.54) .. (-13.84,10.54)
),
1,reverse ((6.48,-11.24)
 .. controls (6.48,-11.24) and (3.65,-7.34) .. (2.16,-5.66)
 .. controls (0.68,-3.98) and (-0.63,-1.84) .. (-1.64,-1.07)
 .. controls (-2.64,-0.30) and (-7.53,3.76) .. (-8.43,4.23)
 .. controls (-9.34,4.71) and (-11.91,5.89) .. (-13.36,4.37)
));
draw_downscrap;
endfig;
background:=(0.25000,0.60250,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.60250, 1.00000);
current_scrap := "D35_20161210SP7@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP7";
beginfig(391);
draw_upscrap(1)(1,((13.05,-17.09)
 .. controls (13.05,-17.09) and (11.98,-13.05) .. (11.37,-10.66)
 .. controls (10.77,-8.29) and (9.68,-5.78) .. (8.83,-3.92)
 .. controls (7.97,-2.06) and (5.09,4.95) .. (4.54,6.58)
 .. controls (3.99,8.21) and (1.33,12.49) .. (0.27,13.64)
 .. controls (-0.79,14.79) and (-5.06,18.58) .. (-5.69,19.07)
),
1,((-13.05,14.42)
 .. controls (-13.05,14.42) and (-6.21,8.36) .. (-4.83,6.38)
 .. controls (-3.45,4.42) and (-2.45,3.96) .. (-1.09,0.51)
 .. controls (0.28,-2.94) and (3.91,-9.63) .. (4.54,-11.04)
 .. controls (5.16,-12.44) and (6.50,-15.37) .. (6.74,-16.17)
 .. controls (6.99,-16.97) and (7.77,-19.07) .. (7.77,-19.07)
));
draw_downscrap;
endfig;
background:=(0.25000,0.58000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.58000, 1.00000);
current_scrap := "D35_20161210SP6@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP6";
beginfig(392);
draw_upscrap(1)(1,((6.62,-26.64)
 .. controls (6.62,-26.64) and (6.78,-23.81) .. (6.91,-21.84)
 .. controls (7.05,-19.86) and (6.93,-17.06) .. (6.50,-14.73)
 .. controls (6.08,-12.40) and (6.96,-12.01) .. (5.74,-8.90)
 .. controls (4.52,-5.80) and (3.11,2.79) .. (2.64,4.68)
 .. controls (2.16,6.57) and (-1.59,25.17) .. (-1.76,26.64)
),
1,((-7.05,24.66)
 .. controls (-7.03,23.77) and (-6.65,20.44) .. (-6.54,17.92)
 .. controls (-6.43,15.39) and (-5.37,4.83) .. (-4.96,1.55)
 .. controls (-4.55,-1.74) and (-3.09,-8.11) .. (-3.19,-9.55)
 .. controls (-3.30,-10.98) and (-3.25,-14.86) .. (-3.75,-17.63)
 .. controls (-4.26,-20.39) and (-4.86,-23.10) .. (-4.86,-23.10)
));
draw_downscrap;
endfig;
background:=(0.25000,0.55000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.55000, 1.00000);
current_scrap := "D35_20161210SP5@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP5";
beginfig(393);
draw_upscrap(1)(1,((8.30,21.48)
 .. controls (8.30,21.48) and (7.62,10.93) .. (7.59,9.22)
 .. controls (7.56,7.51) and (8.01,-8.90) .. (8.38,-12.08)
 .. controls (8.75,-15.27) and (9.71,-28.78) .. (11.94,-32.49)
 .. controls (14.16,-36.21) and (15.49,-43.75) .. (15.70,-47.87)
 .. controls (15.91,-51.98) and (15.81,-54.19) .. (18.37,-56.30)
 .. controls (19.52,-57.26) and (20.17,-58.32) .. (20.17,-58.32)
),
1,((28.76,-52.10)
 .. controls (28.76,-52.10) and (27.46,-52.69) .. (27.40,-50.34)
 .. controls (27.33,-47.99) and (28.11,-45.83) .. (27.56,-44.62)
 .. controls (27.02,-43.41) and (24.41,-35.47) .. (23.34,-33.87)
 .. controls (22.28,-32.26) and (21.41,-29.13) .. (20.57,-28.31)
 .. controls (19.72,-27.48) and (18.63,-19.20) .. (18.80,-16.64)
 .. controls (18.98,-14.08) and (20.61,-4.76) .. (19.85,-1.37)
 .. controls (19.09,2.02) and (19.71,15.01) .. (19.78,17.94)
));
draw_downscrap;
endfig;
background:=(0.25000,0.52000,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.52000, 1.00000);
current_scrap := "D35_20161210SP3@D35_20161210.D35projet";
ATTR__scrap := "D35_20161210SP3";
beginfig(394);
draw_upscrap(1)(1,((27.85,-58.23)
 .. controls (27.85,-58.23) and (25.34,-54.00) .. (23.45,-52.02)
 .. controls (21.55,-50.04) and (17.40,-43.48) .. (16.53,-41.08)
 .. controls (15.66,-38.67) and (14.84,-32.93) .. (14.76,-30.80)
 .. controls (14.68,-28.68) and (13.90,-16.45) .. (13.55,-14.93)
 .. controls (13.20,-13.42) and (11.65,-5.92) .. (11.64,-4.65)
 .. controls (11.64,-3.39) and (8.18,9.21) .. (7.24,12.61)
 .. controls (6.30,16.01) and (7.23,14.37) .. (6.15,17.11)
 .. controls (5.08,19.84) and (4.24,21.39) .. (3.94,23.03)
 .. controls (3.65,24.68) and (2.94,28.74) .. (2.09,30.83)
 .. controls (1.24,32.92) and (-0.80,36.67) .. (-1.93,39.27)
 .. controls (-3.06,41.87) and (-6.60,46.18) .. (-7.85,47.03)
),
1,((-7.85,47.03)
 .. controls (-7.85,47.03) and (-8.96,51.12) .. (-15.92,47.05)
),
0,((-15.92,47.05)
 .. controls (-15.92,47.05) and (-24.56,42.81) .. (-24.51,40.83)
),
1,((-24.51,40.83)
 .. controls (-24.51,40.83) and (-23.65,38.24) .. (-22.71,36.82)
 .. controls (-21.77,35.41) and (-19.54,31.15) .. (-19.19,30.36)
 .. controls (-18.84,29.56) and (-17.01,27.32) .. (-16.18,26.27)
 .. controls (-15.35,25.22) and (-9.77,23.08) .. (-6.61,22.45)
 .. controls (-3.45,21.83) and (-1.57,20.21) .. (-1.45,18.13)
 .. controls (-1.32,16.04) and (-0.81,14.34) .. (-0.21,12.49)
 .. controls (0.38,10.65) and (0.71,5.62) .. (1.13,2.48)
 .. controls (1.54,-0.66) and (2.44,-6.05) .. (2.84,-7.38)
 .. controls (3.24,-8.72) and (5.88,-17.56) .. (5.86,-19.14)
 .. controls (5.85,-20.72) and (7.09,-31.45) .. (7.57,-35.63)
 .. controls (8.05,-39.81) and (8.77,-43.74) .. (9.27,-45.04)
 .. controls (9.77,-46.34) and (9.95,-46.30) .. (10.97,-47.77)
 .. controls (12.00,-49.24) and (15.20,-52.62) .. (16.27,-53.46)
 .. controls (17.34,-54.30) and (18.60,-56.19) .. (18.60,-56.19)
));
draw_downscrap;
endfig;
beginfig(395);
s_northarrow(0);
endfig;
beginfig(396);
s_scalebar(100, 1, "\thfb\char109 \mainfont{}");
endfig;
Scale:=4.00;
initialize(Scale);
background:=(1.00000,1.00000,1.00000);
transparency:=false;
beginfig(397);
clean_legend_box;
drawoptions();
p_entrance((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(398);
clean_legend_box;
drawoptions();
l_mapconnection(((0.2,0.8) -- (0.8,0.2)) inscale)draw_legend_box;
endfig;
beginfig(399);
clean_legend_box;
drawoptions();
l_wall_bedrock(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(400);
clean_legend_box;
drawoptions();
l_wall_unsurveyed(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(401);
clean_legend_box;
drawoptions();
l_wall_presumed(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(402);
clean_legend_box;
drawoptions();
l_wall_debris(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(403);
clean_legend_box;
drawoptions();
p_label.rt(btex \thaltitude \thfb\char49 \char53 \char49 \char48 \mainfont{} etex,((0.3,0.5) inscale),0,1);
draw_legend_box;
endfig;
beginfig(404);
clean_legend_box;
drawoptions();
p_airdraught_winter((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(405);
clean_legend_box;
drawoptions();
p_airdraught_summer((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(406);
clean_legend_box;
drawoptions();
p_dig((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(407);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_wall_bedrock(((0,.2){dir 30} .. {dir 0}(.5,.4)) inscale);
l_wall_bedrock(((.5,.6){dir 180} .. {dir 210}(0,.8)) inscale);
drawoptions();
drawoptions(withcolor (1.000000,0.000000,0.000000));
p_continuation((.6,.5) inscale,270.0,1.0,(0,1));
draw_legend_box;
endfig;
beginfig(408);
clean_legend_box;
drawoptions();
l_floorstep((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale));
draw_legend_box;
endfig;
beginfig(409);
clean_legend_box;
drawoptions();
l_floormeander((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale));
draw_legend_box;
endfig;
beginfig(410);
clean_legend_box;
drawoptions();
l_pit((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
drawoptions();
beginfig(411);
clean_legend_box;
drawoptions();
p_gradient((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(412);
clean_legend_box;
drawoptions();
l_rockborder(((.16,.36) -- (.61,.21) -- (.91,.46) -- (.84,.78) -- (.38,.86) -- (.20,.55) -- cycle) inscale)draw_legend_box;
endfig;
beginfig(413);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_rockborder(((.16,.36) -- (.61,.21) -- (.91,.46) -- (.84,.78) -- (.38,.86) -- (.20,.55) -- cycle) inscale)drawoptions();
drawoptions();
l_rockedge(((.16,.36) -- (.42,.62) -- (.38,.86) -- (.42,.62) -- (.6,.55) -- (.61,.21) -- (.6,.55) -- (.84,.78)) inscale)draw_legend_box;
endfig;
beginfig(414);
clean_legend_box;
drawoptions();
p_clay((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(415);
clean_legend_box;
drawoptions();
l_border_visible((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
beginfig(416);
clean_legend_box;
drawoptions();
l_border_presumed((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
beginfig(417);
clean_legend_box;
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_water(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(418);
clean_legend_box;
drawoptions(withcolor (0.000000,0.000000,0.000000));
a_sump(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(419);
clean_legend_box;
drawoptions();
l_waterflow_permanent(((0.1,0.3) -- (0.9,0.3)) inscale);
drawoptions(withcolor (0.000000,0.000000,0.000000));
p_waterflow_permanent((0.5,0.7) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(420);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_waterflow_permanent(((0.3,0.5) -- (0.9,0.5)) inscale);
drawoptions();
drawoptions(withcolor (0.000000,0.000000,0.000000));
p_spring((0.3,0.5) inscale,270,1.0,(0,-1));
draw_legend_box;
endfig;
beginfig(421);
clean_legend_box;
drawoptions();
p_flowstone((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(422);
clean_legend_box;
drawoptions();
p_moonmilk((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(423);
clean_legend_box;
drawoptions();
p_camp((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(424);
s_hgrid(-1, -1, 354.33071, 354.33071);
endfig;
beginfig(425);
s_hgrid(0, -1, 354.33071, 354.33071);
endfig;
beginfig(426);
s_hgrid(1, -1, 354.33071, 354.33071);
endfig;
beginfig(427);
s_hgrid(-1, 0, 354.33071, 354.33071);
endfig;
beginfig(428);
s_hgrid(0, 0, 354.33071, 354.33071);
endfig;
beginfig(429);
s_hgrid(1, 0, 354.33071, 354.33071);
endfig;
beginfig(430);
s_hgrid(-1, 1, 354.33071, 354.33071);
endfig;
beginfig(431);
s_hgrid(0, 1, 354.33071, 354.33071);
endfig;
beginfig(432);
s_hgrid(1, 1, 354.33071, 354.33071);
endfig;
end;
