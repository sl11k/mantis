// ============================================================================
//  MANTIS - Multimodal Autonomous Non-Invasive Technical Inspection System
//  Portable inspection device  |  PARAMETRIC PROTOTYPE ENCLOSURE (FDM)
//  File: mantis_enclosure.scad          Rev B  2026-10-01
// ----------------------------------------------------------------------------
//  HOW TO USE
//    1. Set view_mode below (or use Window > Customizer).
//    2. view_mode = "bottom"  -> F6 -> File > Export > Export as STL
//       view_mode = "top"     -> F6 -> File > Export > Export as STL
//    3. Placeholders, labels and wire paths are NEVER generated in the
//       "top" / "bottom" modes, so they can never end up in a printed STL.
//
//  COORDINATES (assembled)          Z = 0 is the machine-contact face
//    -X = LEFT  wall  : USB access + power switch
//    +X = RIGHT wall  : IR thermal sensor window
//    -Y = FRONT wall,  +Y = BACK wall  (strap lugs on both)
//
//  ZONES (top view)
//    +Y  [ A: ARDUINO  (USB->left wall) ][ C2: VIBRATION POCKET ]
//        [ gutter |  B: 2 x 18650 POWER (along X) | gutter+C3 IR ]
//    -Y  [ D1: EXPANSION ][ C1: PIEZO (floor) ][ D2: EXPANSION ]
//  All dimensions in mm.
// ============================================================================

/* [View] */
// What to show / export
view_mode = "assembled"; // [assembled, top, bottom, exploded, internal_layout, section]
// "top" mode: flip the top shell roof-down (ready-to-print orientation)
print_orientation = true;
// Placeholder parts in assembled / exploded / section views
show_components = true;
show_labels = true;
show_wire_paths = true;
show_screws = true;
// Transparent ghost of the lid in internal_layout view
show_lid_ghost = false;
explode_gap = 45;
// Y position of the cut plane in "section" view (37.5 = through the Arduino)
section_y = 37.5;

/* [Enclosure] */
enclosure_width  = 120; // X  (100 is too small - see FIT CHECK at the end)
enclosure_length = 120; // Y
enclosure_height = 45;  // Z
wall_thickness   = 3.0;
floor_thickness  = 3.0;
roof_thickness   = 2.5;
corner_radius    = 10;
// Parting line height = bottom shell height (top shell = rest)
split_height     = 30;
top_edge_chamfer    = 2.0;
bottom_edge_chamfer = 0.8;
seam_chamfer        = 0.6;

/* [Tolerances] */
tolerance         = 0.4;  // general fit clearance
lip_clearance     = 0.25; // tongue -> lid rebate
battery_clearance = 0.5;  // added to the cell diameter
pcb_clearance     = 0.75; // keep-out around the Arduino PCB (each side)

/* [Shell joint and screws] */
lip_height    = 4;
lip_thickness = 1.2;              // lid keeps wall - lip - clearance = 1.55 mm
screw_diameter = 3;              // M3 (M2.5 possible: scale the values below)
screw_clearance_diameter = 3.4;
screw_head_diameter = 6.5;       // counterbore (M3 socket head = 5.5)
screw_head_depth = 4.5;          // counterbore depth -> M3 x 16 screws
screw_inset = 8;                 // screw axis distance from outer side faces
boss_diameter = 9;
// 4.0 = M3 heat-set insert (OD 4.2-4.6, L 5.7) | 2.5 = direct self-tapping M3
boss_hole_diameter = 4.0;
boss_hole_depth = 7;

/* [Magnets] */
magnet_diameter  = 20;
magnet_thickness = 5;
magnet_clearance = 0.4;  // on diameter - glue gap
magnet_skin      = 0.8;  // plastic between magnet and machine (4 layers @ 0.2)
magnet_cup_wall  = 1.6;
magnet_inset     = 19;   // magnet centre distance from outer side faces

/* [Battery] */
battery_option = "18650_cradle"; // [18650_cradle, pack_bay]
battery_diameter  = 18.5;
battery_length    = 65;
battery_end_space = 5;    // per end: spring / plate contact, protected cells
battery_divider   = 1.0;  // web between the two cells
battery_floor_gap = 2.5;  // under the cells: a hook-and-loop strap passes here
battery_end_wall  = 3.5;
saddle_thickness  = 3;
contact_plate_width = 12.5;
contact_plate_thickness = 1.2;
battery_center = [0, 0];
// Option B: compact Li-ion/LiPo pack or a commercial 2x18650 holder
pack_width  = 42;  // Y
pack_length = 78;  // X
pack_height = 22;

/* [Arduino Nano 33 BLE Sense Rev2] */
arduino_length = 43.16;          // datasheet ABX00069
arduino_width  = 17.76;
arduino_height = 3.0;            // tallest top-side part (USB receptacle)
arduino_pcb_thickness = 1.6;
arduino_hole_spacing_x = 40.64;  // 4 x d1.65 holes, 1.26 from the edges
arduino_hole_spacing_y = 15.24;
arduino_hole_diameter  = 1.65;
// floor -> PCB underside: pins-down headers (8.5) clear the magnet cup
arduino_standoff = 12.5;
arduino_center_y = 37.5;         // back edge clears the corner screw boss
arduino_usb_overhang = 1.5;      // micro-USB receptacle sticks out past the PCB
arduino_wall_gap = 0.3;          // USB receptacle face -> inner wall
arduino_peg_diameter = 1.4;      // locating pegs into the PCB holes (0 = none)
arduino_holddown = true;         // lid posts clamp the board when closed
holddown_gap = 0.4;
// MP34DT06 microphone port: from the USB-end PCB edge / from PCB centre line
mic_from_usb_end = 26.0;
mic_offset_y = 1.4;

/* [Openings] */
usb_width  = 13;   // Y - generous for any micro-USB / USB-C over-mould
usb_height = 9;    // Z
usb_connector_height = 2.6;
// 13 x 8.5 = KCD11 mini rocker | 9 x 4 = small slide switch
switch_width  = 13;   // Y
switch_height = 8.5;  // Z
switch_depth  = 14;   // body depth behind the wall (keep-out)
switch_y = 0;
switch_z = 20;
led_diameter = 5.2;          // 5 mm LED or light pipe
led_position = [-4, 40];
led_tube_length = 8;
mic_hole_diameter = 1.2;
mic_hole_pitch = 2.0;
mic_grille_diameter = 6;
mic_duct = true;             // acoustic duct from the grille down to the mic
mic_duct_inner_diameter = 6;
mic_duct_gap = 3;            // duct end above the PCB top (add a foam ring)

/* [Piezo / contact sensor] */
piezo_shape  = "round"; // [round, rect]
piezo_width  = 27;   // disc diameter (round) or X size (rect)
piezo_length = 27;   // Y size (rect only)
piezo_height = 0.6;  // element thickness (placeholder)
piezo_clearance = 0.8;
// floor left under the element; 0 = through-hole + ledge (direct-contact puck)
piezo_skin = 1.0;
piezo_ledge = 1.5;
piezo_center = [0, -41];
piezo_ring = true;   // low ring that locates a foam backing pad / weight

/* [IR thermal sensor] */
thermal_sensor_width  = 12;   // along the wall (Y) - e.g. GY-906 / MLX90614
thermal_sensor_length = 17;   // vertical (Z)
thermal_sensor_height = 6.5;  // depth from the wall incl. sensor can (X)
thermal_pcb_thickness = 1.6;
thermal_can_diameter  = 9.2;  // TO-39 can
thermal_fov = 90;             // full field of view -> window flare
thermal_y = 0;
thermal_base_z = 8;           // module bottom edge height

/* [External vibration sensor] */
vibration_sensor_width  = 25; // X
vibration_sensor_length = 20; // Y
vibration_sensor_height = 5;  // Z
vibration_center = [12, 43.5];
vibration_pad_height = 2;
vibration_fence_height = 3;
vibration_hole_diameter = 2.2; // M2.5 self-tapping pilot
vibration_hole_spacing = 18;

/* [Expansion] */
expansion_width  = 28;  // X
expansion_length = 29;  // Y
expansion_height = 18;  // Z
expansion_center = [-32.5, -40.5];  // D1; D2 is the mirror image (+X)
expansion_floor_z = 7;              // reserved volume starts above the magnet cup
expansion_second_bay = true;

/* [Internal ribs and cable routing] */
rib_thickness = 1.6;
rib_height = 8;
rib_back_y  = 24;
rib_front_y = -24;
rib_divider_x = 17;          // dividers at +/- this X in the front band
rib_notch_width = 10;
rib_notch_depth = 6;
back_rib_notches  = [-49, 45];
front_rib_notches = [-49, 45];
cable_anchor_positions = [[-49, 14], [-49, -14], [45, 14], [45, -14]];

/* [Bottom face] */
rubber_pads = true;
pad_diameter = 10;
pad_recess = 1.0;
pad_positions = [[-22, -50], [22, -50], [-22, 50], [22, 50]];
strap_slots = true;
strap_width = 26;          // slot length (25 mm hook-and-loop strap)
strap_slot_thickness = 4;
strap_lug_depth = 8;
strap_lug_height = 12;
bottom_markings = true;

/* [Top panel] */
logo_text = "MANTIS";
logo_size = 11;
logo_depth = 0.6;
logo_position = [0, -14];
panel_groove = true;
panel_inset = 9;

/* [Hidden] */
$fa = 6;
$fs = 0.5;
EPS = 0.01;

// ============================================================================
//  DERIVED VALUES
// ============================================================================
W = enclosure_width;  L = enclosure_length;  H = enclosure_height;
R = corner_radius;
IX = W/2 - wall_thickness;           // interior half sizes
IY = L/2 - wall_thickness;
RI = max(0.5, R - wall_thickness);   // interior corner radius
FZ = floor_thickness;                // inner floor plane
HB = split_height;                   // parting line
HT = H - split_height;               // top shell height
ROOF_Z = H - roof_thickness;         // inner roof plane

SCREW_POS = [for (sx = [-1, 1], sy = [-1, 1])
             [sx*(W/2 - screw_inset), sy*(L/2 - screw_inset), sx, sy]];
MAG_POS   = [for (sx = [-1, 1], sy = [-1, 1])
             [sx*(W/2 - magnet_inset), sy*(L/2 - magnet_inset)]];
MAG_D     = magnet_diameter + magnet_clearance;
MAG_DEPTH = magnet_thickness + 0.3;
MAG_TOP   = magnet_skin + MAG_DEPTH;
MAG_CUP_D = MAG_D + 2*magnet_cup_wall;

CELL_D     = battery_diameter + battery_clearance;
CELL_PITCH = CELL_D + battery_divider;
CELL_Z     = FZ + battery_floor_gap + CELL_D/2;           // cell axis height
BAY_LEN    = battery_length + 2*battery_end_space + battery_clearance;
BAY_W      = 2*CELL_D + battery_divider + 4;
SADDLE_X   = [-(BAY_LEN/2 - 12), 0, BAY_LEN/2 - 12];

PCB_Z    = FZ + arduino_standoff;                         // PCB underside
PCB_TOP  = PCB_Z + arduino_pcb_thickness;
BOARD_X0 = -IX + arduino_wall_gap + arduino_usb_overhang; // USB-end PCB edge
BOARD_X1 = BOARD_X0 + arduino_length;
BOARD_Y  = arduino_center_y;
HOLE_X0  = (arduino_length - arduino_hole_spacing_x)/2;   // 1.26
ARD_HOLES = [for (i = [0, 1], j = [-1, 1])
             [BOARD_X0 + HOLE_X0 + i*arduino_hole_spacing_x,
              BOARD_Y + j*arduino_hole_spacing_y/2, i == 0 ? -1 : 1, j]];
USB_Z = PCB_TOP + usb_connector_height/2;
MIC   = [BOARD_X0 + mic_from_usb_end, BOARD_Y + mic_offset_y];
HOLDDOWNS = [
  [BOARD_X0 + 2.0, BOARD_Y, PCB_TOP + usb_connector_height + holddown_gap],
  for (j = [-1, 1])
    [BOARD_X0 + HOLE_X0 + arduino_hole_spacing_x + 1.0,
     BOARD_Y + j*arduino_hole_spacing_y/2, PCB_TOP + holddown_gap]
];

IR_Z       = thermal_base_z + thermal_sensor_length/2;    // window centre
IR_PCB_X0  = IX - thermal_sensor_height;                  // PCB back face
IR_WIN_IN  = thermal_can_diameter + 1.3;
IR_WIN_OUT = IR_WIN_IN + 2*(wall_thickness + 0.2)*tan(thermal_fov/2);

VIB_IN  = [vibration_sensor_width + 1, vibration_sensor_length + 1];
VIB_OUT = VIB_IN + [3.2, 3.2];

PZ_OUT = (piezo_shape == "rect" ? max(piezo_width, piezo_length) : piezo_width)
         + piezo_clearance;

C_BOTTOM = [0.24, 0.26, 0.29];
C_TOP    = [0.17, 0.19, 0.21];

// ============================================================================
//  BASIC SHAPES
// ============================================================================
module rr2d(w, l, r) {
  rr = max(0.05, min(r, w/2 - 0.05, l/2 - 0.05));
  offset(r = rr) square([max(0.01, w - 2*rr), max(0.01, l - 2*rr)], center = true);
}

// Rounded box from z = 0 to h with optional 45 deg chamfers (cb bottom, ct top)
module rounded_enclosure(w = W, l = L, h = H, r = R, cb = 0, ct = 0) {
  hull() {
    translate([0, 0, cb]) linear_extrude(max(EPS, h - cb - ct)) rr2d(w, l, r);
    if (cb > 0) linear_extrude(EPS) rr2d(w - 2*cb, l - 2*cb, r - cb);
    if (ct > 0) translate([0, 0, h - EPS]) linear_extrude(EPS) rr2d(w - 2*ct, l - 2*ct, r - ct);
  }
}

module interior_2d(grow = 0) rr2d(2*IX + 2*grow, 2*IY + 2*grow, RI + grow);

module interior_clip(z0, z1, grow = 0.2)
  translate([0, 0, z0]) linear_extrude(z1 - z0) interior_2d(grow);

// Zip-tie anchor: bridge with a tunnel along X (cables run along Y on top)
module tie_anchor(p, span = 4.5, tunnel_h = 2.6, depth = 4) {
  translate([p[0], p[1], FZ - EPS]) difference() {
    translate([-depth/2, -(span/2 + 2), 0]) cube([depth, span + 4, tunnel_h + 1.8]);
    translate([-depth/2 - 1, -span/2, -1]) cube([depth + 2, span, tunnel_h + 1]);
  }
}

// ============================================================================
//  BOTTOM SHELL
// ============================================================================
module bottom_shell() {
  difference() {
    union() {
      difference() {
        rounded_enclosure(W, L, HB, R, bottom_edge_chamfer, seam_chamfer);
        translate([0, 0, FZ]) linear_extrude(HB) interior_2d();
      }
      shell_lip();
      intersection() {
        interior_clip(0, HB);
        union() {
          screw_bosses();
          magnet_bosses();
          battery_holder();
          arduino_mount();
          piezo_ring_add();
          thermal_sensor_mount();
          vibration_mount();
          zone_ribs();
          cable_channels();
        }
      }
      if (strap_slots) strap_lugs();
    }
    magnet_pockets();
    piezo_mount();
    screw_boss_holes();
    usb_cutout();
    switch_cutout();
    thermal_window();
    battery_contact_slots();
    vibration_holes();
    if (strap_slots) strap_slot_cuts();
    if (rubber_pads) rubber_pad_recesses();
    if (bottom_markings) bottom_marks();
  }
}

// Registration tongue: the inner part of the bottom wall continues up past
// the parting line; the lid has a matching rebate in the inner part of its
// wall. Straight runs only (stops before the corner screw bosses).
LIP_O = wall_thickness - lip_thickness;   // tongue outer face, from outside

module lip_mask_2d(extra = 0) {
  eX = W/2 - screw_inset - boss_diameter/2 - 1.5 + extra;
  eY = L/2 - screw_inset - boss_diameter/2 - 1.5 + extra;
  for (sy = [-1, 1]) translate([-eX, sy > 0 ? L/2 - 12 : -L/2]) square([2*eX, 12]);
  for (sx = [-1, 1]) translate([sx > 0 ? W/2 - 12 : -W/2, -eY]) square([12, 2*eY]);
}

module shell_lip() {
  translate([0, 0, HB - EPS]) linear_extrude(lip_height + EPS) intersection() {
    difference() {
      rr2d(W - 2*LIP_O, L - 2*LIP_O, R - LIP_O);
      interior_2d();
    }
    lip_mask_2d();
  }
}

module lid_rebate() {
  o = LIP_O - lip_clearance;
  translate([0, 0, HB - 1]) linear_extrude(lip_height + 0.3 + 1) intersection() {
    difference() {
      rr2d(W - 2*o, L - 2*o, R - o);
      interior_2d(-0.2);
    }
    lip_mask_2d(0.5);
  }
}

module screw_bosses() {
  for (p = SCREW_POS) hull() {
    translate([p[0], p[1], 0]) cylinder(d = boss_diameter, h = HB);
    translate([p[0] + p[2]*5, p[1] + p[3]*5, 0]) cylinder(d = boss_diameter, h = HB);
  }
}

module screw_boss_holes() {
  for (p = SCREW_POS) translate([p[0], p[1], 0]) {
    translate([0, 0, HB - boss_hole_depth]) cylinder(d = boss_hole_diameter, h = boss_hole_depth + 1);
    translate([0, 0, HB - 0.6]) cylinder(d1 = boss_hole_diameter, d2 = boss_hole_diameter + 1.2, h = 0.61);
    // screw-tip clearance / self-tapping pilot below the insert
    translate([0, 0, HB - boss_hole_depth - 6]) cylinder(d = screw_diameter - 0.4, h = 6.1);
  }
}

// ---------------------------------------------------------------- magnets ---
module magnet_bosses() {
  for (p = MAG_POS) translate([p[0], p[1], 0]) cylinder(d = MAG_CUP_D, h = max(MAG_TOP, FZ));
}

// Opened from the inside, closed by a thin skin at the machine face.
module magnet_pockets() {
  for (p = MAG_POS) translate([p[0], p[1], magnet_skin]) {
    cylinder(d = MAG_D, h = MAG_DEPTH + 1);
    // pry / glue-overflow notch, pointing to the device centre
    rotate([0, 0, atan2(-p[1], -p[0])])
      translate([MAG_D/2 - 0.5, -1.5, MAG_DEPTH - 2]) cube([1.5, 3, 3]);
  }
}

// ---------------------------------------------------------------- battery ---
module battery_holder() {
  translate([battery_center[0], battery_center[1], 0]) {
    if (battery_option == "18650_cradle") {
      for (x = SADDLE_X) translate([x, 0, 0]) battery_saddle();
      for (s = [-1, 1])
        translate([s*(BAY_LEN/2 + battery_end_wall/2) - battery_end_wall/2, -BAY_W/2, FZ - EPS])
          cube([battery_end_wall, BAY_W, CELL_Z + 7 - FZ]);
    } else {
      pack_bay();
    }
  }
}

module battery_saddle() {
  difference() {
    translate([-saddle_thickness/2, -BAY_W/2, FZ - EPS])
      cube([saddle_thickness, BAY_W, CELL_Z - 1 - FZ + EPS]);
    for (s = [-1, 1]) translate([-saddle_thickness, s*CELL_PITCH/2, CELL_Z])
      rotate([0, 90, 0]) cylinder(d = CELL_D, h = 2*saddle_thickness);
  }
}

// Slots for standard spring/plate battery contacts (drop in from the top)
module battery_contact_slots() {
  if (battery_option == "18650_cradle")
    translate([battery_center[0], battery_center[1], 0])
      for (s = [-1, 1], c = [-1, 1]) {
        xw = s*(BAY_LEN/2 + battery_end_wall/2);
        yc = c*CELL_PITCH/2;
        translate([xw - contact_plate_thickness/2, yc - contact_plate_width/2,
                   CELL_Z - contact_plate_width/2 - 0.5])
          cube([contact_plate_thickness, contact_plate_width, 30]);
        // window so the spring / button reaches the cell
        translate([s > 0 ? xw - battery_end_wall : xw, yc - (contact_plate_width - 3)/2,
                   CELL_Z - contact_plate_width/2 + 1])
          cube([battery_end_wall, contact_plate_width - 3, 30]);
      }
}

// Option B - flat bay with a low fence and two strap bridges
module pack_bay() {
  pw = pack_length + 2*tolerance;
  pl = pack_width + 2*tolerance;
  translate([0, 0, FZ - EPS]) linear_extrude(6) difference() {
    square([pw + 3.2, pl + 3.2], center = true);
    square([pw, pl], center = true);
    for (s = [-1, 1]) translate([s*pw/2, 0]) square([8, 10], center = true);
  }
  for (sx = [-1, 1], sy = [-1, 1])
    translate([sx*pw/4, sy*(pl/2 + 5), FZ - EPS]) difference() {
      translate([-13, -2.5, 0]) cube([26, 5, 4.5]);
      translate([-11, -3.5, -1]) cube([22, 7, 3.6]);
    }
}

// ---------------------------------------------------------------- arduino ---
// Corner posts under the 4 PCB holes (outside the header rows) + pegs,
// joined at each end by a bar that stays 1 mm under the PCB.
module arduino_mount() {
  for (h = ARD_HOLES) {
    ox = h[2]; oy = h[3];
    xa = h[0] - ox*1.0;  xb = h[0] + ox*3.3;
    ya = h[1] - oy*1.4;  yb = h[1] + oy*3.3;
    translate([min(xa, xb), min(ya, yb), FZ - EPS])
      cube([abs(xb - xa), abs(yb - ya), PCB_Z - FZ + EPS]);
    if (arduino_peg_diameter > 0)
      translate([h[0], h[1], PCB_Z - EPS]) {
        cylinder(d = arduino_peg_diameter, h = arduino_pcb_thickness - 0.6);
        translate([0, 0, arduino_pcb_thickness - 0.6 - EPS])
          cylinder(d1 = arduino_peg_diameter, d2 = arduino_peg_diameter - 0.5, h = 0.4);
      }
  }
  for (i = [0, 1]) {
    hx = BOARD_X0 + HOLE_X0 + i*arduino_hole_spacing_x;
    ox = i == 0 ? -1 : 1;
    translate([min(hx - ox*1.0, hx + ox*3.3), BOARD_Y - arduino_hole_spacing_y/2 - 3.3, FZ - EPS])
      cube([4.3, arduino_hole_spacing_y + 6.6, PCB_Z - 1.0 - FZ]);
  }
}

// ------------------------------------------------------------------ piezo ---
module piezo_2d(grow = 0) {
  if (piezo_shape == "rect") square([piezo_width + 2*grow, piezo_length + 2*grow], center = true);
  else circle(d = piezo_width + 2*grow);
}

// Pocket in the floor: the element is glued to a thin skin (or, with
// piezo_skin = 0, sits on a ledge over a through-hole for a contact puck).
module piezo_mount() {
  translate([piezo_center[0], piezo_center[1], 0]) {
    if (piezo_skin > 0) {
      translate([0, 0, piezo_skin]) linear_extrude(FZ + 10) piezo_2d(piezo_clearance/2);
    } else {
      translate([0, 0, 1.0]) linear_extrude(FZ + 10) piezo_2d(piezo_clearance/2);
      translate([0, 0, -1]) linear_extrude(FZ + 2) piezo_2d(-piezo_ledge);
    }
  }
}

module piezo_ring_add() {
  if (piezo_ring) translate([piezo_center[0], piezo_center[1], FZ - EPS])
    linear_extrude(3) difference() {
      piezo_2d(piezo_clearance/2 + 1.2);
      piezo_2d(piezo_clearance/2);
      rotate(20) translate([PZ_OUT/2, 0]) square([6, 4], center = true);  // cable exit
    }
}

// ------------------------------------------------------------- IR sensor ---
// Card guides on the right wall: the module PCB drops in from above and
// stands on a ledge, sensor can facing the open window.
module thermal_sensor_mount() {
  gi = thermal_can_diameter/2 + 0.8;               // guide inner face
  go = thermal_sensor_width/2 + 0.3 + 1.6;         // guide outer face
  xb = IR_PCB_X0 - 1.2;
  ztop = thermal_base_z + thermal_sensor_length;
  for (s = [-1, 1]) difference() {
    translate([xb, thermal_y + (s > 0 ? gi : -go), FZ - EPS])
      cube([IX - xb + 0.2, go - gi, ztop - FZ]);
    translate([IR_PCB_X0 - 0.3,
               thermal_y + (s > 0 ? gi - 1 : -(thermal_sensor_width/2 + 0.3)),
               thermal_base_z])
      cube([thermal_pcb_thickness + 0.6, thermal_sensor_width/2 + 0.3 - gi + 1, 40]);
  }
  translate([xb, thermal_y - go, FZ - EPS]) cube([IX - xb + 0.2, 2*go, thermal_base_z - FZ]);
}

// Open window (no plastic in the optical path), flared to the sensor FOV
module thermal_window() {
  translate([W/2, thermal_y, IR_Z]) hull() {
    translate([-wall_thickness - 0.2, 0, 0]) cube([EPS, IR_WIN_IN, IR_WIN_IN], center = true);
    translate([0.1, 0, 0]) cube([EPS, IR_WIN_OUT, IR_WIN_OUT], center = true);
  }
}

// ------------------------------------------------------ vibration sensor ---
module vibration_mount() {
  translate([vibration_center[0], vibration_center[1], FZ - EPS]) {
    linear_extrude(vibration_pad_height + EPS) square(VIB_OUT, center = true);
    translate([0, 0, vibration_pad_height]) linear_extrude(vibration_fence_height) difference() {
      square(VIB_OUT, center = true);
      square(VIB_IN, center = true);
      translate([-VIB_OUT[0]/2, 0]) square([5, 8], center = true);   // cable exit
    }
  }
}

module vibration_holes() {
  for (s = [-1, 1])
    translate([vibration_center[0] + s*vibration_hole_spacing/2, vibration_center[1],
               FZ + vibration_pad_height - 4])
      cylinder(d = vibration_hole_diameter, h = 5);
}

// -------------------------------------------------------------- expansion ---
// Zone D is reserved empty space (front-left D1, front-right D2). Only its
// divider ribs are printed; the volume itself is shown as a placeholder.
module expansion_zone() {
  for (m = expansion_second_bay ? [-1, 1] : [1])
    translate([m*expansion_center[0] - expansion_width/2,
               expansion_center[1] - expansion_length/2, expansion_floor_z])
      cube([expansion_width, expansion_length, expansion_height]);
}

// ------------------------------------------------------- ribs and cables ---
module zone_ribs() {
  for (r = [[rib_back_y, back_rib_notches], [rib_front_y, front_rib_notches]])
    difference() {
      translate([-IX - 0.2, r[0] - rib_thickness/2, FZ - EPS])
        cube([2*IX + 0.4, rib_thickness, rib_height + EPS]);
      for (n = r[1])
        translate([n - rib_notch_width/2, r[0] - 2, FZ + rib_height - rib_notch_depth])
          cube([rib_notch_width, 4, rib_notch_depth + 1]);
    }
  // dividers between expansion bays and the piezo zone
  for (s = [-1, 1]) difference() {
    translate([s*rib_divider_x - rib_thickness/2, -IY - 0.2, FZ - EPS])
      cube([rib_thickness, rib_front_y + IY + 0.2, rib_height + EPS]);
    translate([s*rib_divider_x - 2, (rib_front_y - IY)/2 - rib_notch_width/2,
               FZ + rib_height - rib_notch_depth])
      cube([4, rib_notch_width, rib_notch_depth + 1]);
  }
}

// Wiring: left gutter = power, right gutter = sensor signals, back channel
// (between the back rib and the Arduino) = sensors -> Arduino pins.
module cable_channels() {
  for (p = cable_anchor_positions) tie_anchor(p);
}

// ---------------------------------------------------------------- openings --
module usb_cutout() {
  translate([-W/2 - 1, BOARD_Y, USB_Z]) rotate([0, 90, 0])
    linear_extrude(wall_thickness + 1.2) rr2d(usb_height, usb_width, 1.5);
}

module switch_cutout() {
  translate([-W/2 - 1, switch_y, switch_z]) rotate([0, 90, 0])
    linear_extrude(wall_thickness + 1.2) rr2d(switch_height, switch_width, 0.8);
}

// ------------------------------------------------------------ bottom face ---
module rubber_pad_recesses() {
  for (p = pad_positions) translate([p[0], p[1], -1]) cylinder(d = pad_diameter + 0.5, h = pad_recess + 1);
}

module bottom_marks() {
  // 0.4 mm ring marking the piezo contact zone on the machine face
  translate([piezo_center[0], piezo_center[1], -1]) linear_extrude(1.4) difference() {
    circle(d = PZ_OUT + 6);
    circle(d = PZ_OUT + 4.4);
  }
}

module strap_lugs() {
  lw = strap_width + 8;
  for (sy = [-1, 1]) scale([1, sy, 1]) translate([0, L/2 + (strap_lug_depth - 2)/2, 0]) hull() {
    linear_extrude(strap_lug_height - 1.5) rr2d(lw, strap_lug_depth + 2, 3);
    linear_extrude(strap_lug_height) rr2d(lw - 3, strap_lug_depth - 1, 1.5);
  }
}

module strap_slot_cuts() {
  for (sy = [-1, 1]) scale([1, sy, 1])
    translate([-strap_width/2, L/2, -1]) cube([strap_width, strap_slot_thickness, strap_lug_height + 2]);
}

// ============================================================================
//  TOP SHELL
// ============================================================================
module top_shell() {
  difference() {
    union() {
      difference() {
        translate([0, 0, HB]) rounded_enclosure(W, L, HT, R, seam_chamfer, top_edge_chamfer);
        translate([0, 0, HB - 1]) linear_extrude(ROOF_Z - HB + 1) interior_2d();
      }
      intersection() {
        interior_clip(HB - 20, ROOF_Z + EPS);
        union() {
          lid_columns();
          mic_duct();
          led_tube();
          if (arduino_holddown) arduino_holddowns();
        }
      }
    }
    lid_screw_holes();
    lid_rebate();
    microphone_vents();
    led_window();
    logo_engrave();
    if (panel_groove) panel_groove_cut();
  }
}

module lid_columns() {
  for (p = SCREW_POS) hull() {
    translate([p[0], p[1], HB]) cylinder(d = boss_diameter, h = HT);
    translate([p[0] + p[2]*5, p[1] + p[3]*5, HB]) cylinder(d = boss_diameter, h = HT);
  }
}

module lid_screw_holes() {
  for (p = SCREW_POS) translate([p[0], p[1], 0]) {
    translate([0, 0, HB - 1]) cylinder(d = screw_clearance_diameter, h = HT + 2);
    translate([0, 0, H - screw_head_depth]) cylinder(d = screw_head_diameter, h = screw_head_depth + 1);
  }
}

// Posts that clamp the board (on the USB receptacle and the two far corners)
module arduino_holddowns() {
  for (h = HOLDDOWNS) translate([h[0], h[1], h[2]]) {
    cylinder(d = 4, h = ROOF_Z - h[2] + EPS);
    translate([0, 0, ROOF_Z - h[2] - 3]) cylinder(d1 = 4, d2 = 7, h = 3 + EPS);
  }
}

module mic_duct() {
  if (mic_duct) {
    z0 = PCB_TOP + mic_duct_gap;
    translate([MIC[0], MIC[1], z0]) difference() {
      cylinder(d = mic_duct_inner_diameter + 2.4, h = ROOF_Z - z0 + EPS);
      translate([0, 0, -1]) cylinder(d = mic_duct_inner_diameter, h = ROOF_Z - z0 + 2);
    }
  }
}

// Several small holes instead of one large one (hex pattern)
module microphone_vents() {
  for (i = [-4:4], j = [-4:4]) {
    px = i*mic_hole_pitch + (abs(j) % 2)*mic_hole_pitch/2;
    py = j*mic_hole_pitch*0.866;
    if (norm([px, py]) + mic_hole_diameter/2 <= mic_grille_diameter/2)
      translate([MIC[0] + px, MIC[1] + py, ROOF_Z - 1])
        cylinder(d = mic_hole_diameter, h = roof_thickness + 2);
  }
}

module led_tube() {
  translate([led_position[0], led_position[1], ROOF_Z - led_tube_length])
    cylinder(d = led_diameter + 2.4, h = led_tube_length + EPS);
}

module led_window() {
  translate([led_position[0], led_position[1], ROOF_Z - led_tube_length - 1])
    cylinder(d = led_diameter, h = led_tube_length + roof_thickness + 2);
}

module logo_engrave() {
  if (logo_text != "")
    translate([logo_position[0], logo_position[1], H - logo_depth])
      linear_extrude(logo_depth + 1)
        text(logo_text, size = logo_size, font = "Liberation Sans:style=Bold",
             halign = "center", valign = "center", spacing = 1.15);
}

module panel_groove_cut() {
  rp = max(1.5, R - panel_inset + 4);
  translate([0, 0, H - 0.5]) linear_extrude(1) difference() {
    rr2d(W - 2*panel_inset, L - 2*panel_inset, rp);
    rr2d(W - 2*panel_inset - 1.6, L - 2*panel_inset - 1.6, rp - 0.8);
  }
}

// ============================================================================
//  PLACEHOLDERS (preview only - never called in "top" / "bottom" modes)
// ============================================================================
module components() {
  ph_arduino();
  ph_batteries();
  ph_piezo();
  ph_thermal();
  ph_vibration();
  ph_expansion();
  ph_switch();
  ph_magnets();
}

// Arduino Nano 33 BLE Sense Rev2 (PCB, USB receptacle, NINA module, mic,
// gold bars = keep-out for pins-down headers)
module ph_arduino() {
  color("teal") translate([BOARD_X0, BOARD_Y - arduino_width/2, PCB_Z])
    cube([arduino_length, arduino_width, arduino_pcb_thickness]);
  color("silver") translate([BOARD_X0 - arduino_usb_overhang, BOARD_Y - 3.75, PCB_TOP])
    cube([5.6, 7.5, usb_connector_height]);
  color("lightgray") translate([BOARD_X0 + 28.0, BOARD_Y - 4.9, PCB_TOP]) cube([14.5, 9.8, 2.2]);
  color("black") translate([MIC[0], MIC[1], PCB_TOP]) cylinder(d = 2.5, h = 1);
  color([0.85, 0.65, 0.1]) for (j = [-1, 1])
    translate([BOARD_X0 + 2.53, BOARD_Y + j*arduino_hole_spacing_y/2 - 1.27, PCB_Z - 8.5])
      cube([38.1, 2.54, 8.5]);
}

// 2 x 18650 (2S: cell 1 "+" to +X, cell 2 "+" to -X) + contact plates
module ph_batteries() {
  if (battery_option == "18650_cradle") {
    for (i = [0, 1]) translate([battery_center[0], battery_center[1] + (i == 0 ? 1 : -1)*CELL_PITCH/2, CELL_Z])
      scale([i == 0 ? 1 : -1, 1, 1]) translate([-battery_length/2, 0, 0]) rotate([0, 90, 0]) {
        color("royalblue") cylinder(d = battery_diameter, h = battery_length - 1);
        color("silver") translate([0, 0, battery_length - 1]) cylinder(d = 7, h = 1);
      }
    color("silver") for (s = [-1, 1], c = [-1, 1])
      translate([battery_center[0] + s*(BAY_LEN/2 + battery_end_wall/2), battery_center[1] + c*CELL_PITCH/2, CELL_Z])
        cube([contact_plate_thickness - 0.3, contact_plate_width - 0.5, contact_plate_width], center = true);
  } else {
    color("royalblue") translate([battery_center[0] - pack_length/2, battery_center[1] - pack_width/2, FZ])
      cube([pack_length, pack_width, pack_height]);
  }
}

// Piezo disc (brass + ceramic) resting on the pocket floor
module ph_piezo() {
  translate([piezo_center[0], piezo_center[1], piezo_skin > 0 ? piezo_skin : 1.0]) {
    color("goldenrod") linear_extrude(0.3) piezo_2d(0);
    color("white") translate([0, 0, 0.3]) linear_extrude(max(0.1, piezo_height - 0.3)) piezo_2d(-piezo_width*0.13);
  }
}

// IR thermal module: PCB in the card guides, TO-39 can looking out the window
module ph_thermal() {
  color("darkgreen") translate([IR_PCB_X0, thermal_y - thermal_sensor_width/2, thermal_base_z])
    cube([thermal_pcb_thickness, thermal_sensor_width, thermal_sensor_length]);
  color("silver") translate([IR_PCB_X0 + thermal_pcb_thickness, thermal_y, IR_Z]) rotate([0, 90, 0])
    cylinder(d = thermal_can_diameter, h = thermal_sensor_height - thermal_pcb_thickness - 0.05);
}

module ph_vibration() {
  color("mediumpurple")
    translate([vibration_center[0] - vibration_sensor_width/2, vibration_center[1] - vibration_sensor_length/2,
               FZ + vibration_pad_height])
      cube([vibration_sensor_width, vibration_sensor_length, vibration_sensor_height]);
}

module ph_expansion() color([0.62, 0.35, 0.95, 0.45]) expansion_zone();

module ph_switch() {
  color("dimgray") translate([-IX, switch_y - switch_width/2, switch_z - switch_height/2])
    cube([switch_depth, switch_width, switch_height]);
}

module ph_magnets() {
  color("gray") for (p = MAG_POS) translate([p[0], p[1], magnet_skin]) cylinder(d = magnet_diameter, h = magnet_thickness);
}

module screws() {
  color("silver") for (p = SCREW_POS) translate([p[0], p[1], H - screw_head_depth]) {
    cylinder(d = 5.5, h = 3);
    translate([0, 0, -16]) cylinder(d = screw_diameter, h = 16);
  }
}

module label(t, p, s = 4) {
  color("black") translate(p) linear_extrude(0.6)
    text(t, size = s, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
}

module labels() {
  label("ARDUINO", [BOARD_X0 + 15, BOARD_Y - 5.5, PCB_TOP + 3], 3.6);
  label("BATTERY 1", [0, CELL_PITCH/2, CELL_Z + CELL_D/2 + 0.5], 4);
  label("BATTERY 2", [0, -CELL_PITCH/2, CELL_Z + CELL_D/2 + 0.5], 4);
  label("PIEZO", [piezo_center[0], piezo_center[1], FZ + 3.5], 4);
  label("THERMAL", [IX - 16, thermal_y + 12, 27], 3.4);
  label("VIBRATION SENSOR", [vibration_center[0], vibration_center[1], FZ + vibration_pad_height + vibration_sensor_height + 1], 2.6);
  label("EXPANSION D1", [expansion_center[0], expansion_center[1], expansion_floor_z + expansion_height + 1], 3.2);
  if (expansion_second_bay)
    label("EXPANSION D2", [-expansion_center[0], expansion_center[1], expansion_floor_z + expansion_height + 1], 3.2);
  label("SWITCH", [-IX + 9, switch_y - 10, 27], 3);
  label("USB", [-IX + 4, BOARD_Y - 13, 24], 3);
}

module wire(pts, c, d = 1.6) {
  color(c) for (i = [0:len(pts) - 2]) hull() {
    translate(pts[i]) sphere(d = d, $fn = 8);
    translate(pts[i + 1]) sphere(d = d, $fn = 8);
  }
}

module wire_paths() {
  // power: pack terminals (left end) -> switch -> left gutter -> Arduino VIN
  wire([[-39, 10, 23], [-46, 8, 18], [-48, 2, 20], [-48, 12, 9], [-49, 20, 6],
        [-49, 24, 6], [-47, 30, 8], [-50, BOARD_Y - 7.6, PCB_Z - 2]], "red");
  // piezo -> front band -> right gutter -> back channel -> analog pins
  wire([[piezo_center[0], piezo_center[1], FZ + 0.5], [14, -36, 4.5], [32, -27, 5], [45, -24, 6],
        [45, -14, 6], [45, 14, 6], [45, 24, 6], [32, 28, 6], [0, 28.5, 6],
        [-16, 30, 8], [-22, BOARD_Y - 7.6, PCB_Z - 2]], "gold");
  // IR module (I2C) joins the sensor bundle
  wire([[IR_PCB_X0 - 1, thermal_y, thermal_base_z + 3], [47, -3, 6], [45, -14, 6]], "orange");
  // vibration sensor (I2C/SPI) -> Arduino far end
  wire([[vibration_center[0] - VIB_OUT[0]/2, vibration_center[1], FZ + 4], [-6, 40, 8],
        [-14, BOARD_Y - 7.6, PCB_Z - 2]], "orange");
  // expansion D1 -> left gutter (power side)
  wire([[expansion_center[0] + 8, -30, 8], [-32, -26, 6], [-49, -24, 6], [-49, -10, 6], [-48, 2, 12]], "violet");
}

// ============================================================================
//  VIEW SELECTION
// ============================================================================
module section_cutter() translate([-W, section_y, -50]) cube([2*W, 2*L, H + 200]);

if (view_mode == "assembled") {
  color(C_BOTTOM) bottom_shell();
  color(C_TOP) top_shell();
  if (show_screws) screws();
} else if (view_mode == "top") {
  if (print_orientation) translate([0, 0, H]) rotate([180, 0, 0]) top_shell();
  else top_shell();
} else if (view_mode == "bottom") {
  bottom_shell();
} else if (view_mode == "exploded") {
  color(C_BOTTOM) bottom_shell();
  translate([0, 0, explode_gap]) {
    color(C_TOP) top_shell();
    if (show_screws) screws();
  }
  if (show_components) components();
} else if (view_mode == "internal_layout") {
  color(C_BOTTOM) bottom_shell();
  components();
  if (show_labels) labels();
  if (show_wire_paths) wire_paths();
  if (show_lid_ghost) %top_shell();
} else if (view_mode == "section") {
  difference() { color(C_BOTTOM) bottom_shell(); section_cutter(); }
  difference() { color(C_TOP) top_shell(); section_cutter(); }
  if (show_components) difference() { components(); section_cutter(); }
}

// ============================================================================
//  FIT CHECK  (runs on every preview / render - see the console)
// ============================================================================
assert(BAY_LEN + 2*battery_end_wall + 2*10 <= 2*IX,
       "Battery bay + 10 mm wiring gutters do not fit: increase enclosure_width");
assert(norm([magnet_inset - screw_inset, magnet_inset - screw_inset]) >= MAG_D/2 + boss_diameter/2 + 0.5,
       "Magnet pocket collides with a screw boss: change magnet_inset / screw_inset");
assert(battery_option != "18650_cradle" ||
       L/2 - magnet_inset - MAG_CUP_D/2 >= BAY_W/2 + abs(battery_center[1]),
       "Magnet cups collide with the battery cradle");
assert(magnet_skin >= 0.4, "magnet_skin below 0.4 mm will not print reliably");
assert(piezo_skin < FZ, "piezo_skin must be thinner than floor_thickness");
assert(USB_Z + usb_height/2 <= HB - 2, "USB opening crosses the parting line: raise split_height");
assert(switch_z + switch_height/2 <= HB - 2, "Switch opening crosses the parting line");
assert(IR_Z + IR_WIN_OUT/2 <= HB - 2, "IR window crosses the parting line");
assert(CELL_Z + CELL_D/2 < ROOF_Z - 2, "Cells touch the roof: increase enclosure_height");
assert(BOARD_X1 + 4 < vibration_center[0] - VIB_OUT[0]/2, "Arduino overlaps the vibration pocket");
// PCB outline must keep pcb_clearance from the nearest corner screw boss
BOSS_NEAR = [-(W/2 - screw_inset), L/2 - screw_inset];
BOARD_GAP = norm([max(BOARD_X0 - BOSS_NEAR[0], 0, BOSS_NEAR[0] - BOARD_X1),
                  max(BOARD_Y - arduino_width/2 - BOSS_NEAR[1], 0, BOSS_NEAR[1] - BOARD_Y - arduino_width/2)])
            - boss_diameter/2;
assert(BOARD_GAP >= pcb_clearance, str("Arduino PCB only ", BOARD_GAP, " mm from a screw boss: lower arduino_center_y"));
assert(BOARD_Y - arduino_hole_spacing_y/2 - 3.3 > rib_back_y + rib_thickness/2 + 0.5, "Arduino posts hit the back rib");
assert(-IX + switch_depth < battery_center[0] - BAY_LEN/2 - battery_end_wall,
       "Switch body hits the battery end wall");
if (PCB_Z - 8.5 < MAG_TOP + 0.5)
  echo("WARNING: pins-down headers would touch the magnet cup - raise arduino_standoff");

echo(str("MANTIS | external ", W, " x ", L, " x ", H, " mm | internal ",
         2*IX, " x ", 2*IY, " x ", ROOF_Z - FZ, " mm | split at Z=", HB));
echo(str("MANTIS | battery bay ", BAY_LEN, " x ", BAY_W, " mm, cell axis Z=", CELL_Z,
         " | wiring gutters ", IX - BAY_LEN/2 - battery_end_wall, " mm each side"));
echo(str("MANTIS | Arduino PCB underside Z=", PCB_Z, ", USB centre Z=", USB_Z,
         " | IR window centre Z=", IR_Z, " (", IR_WIN_IN, " -> ", IR_WIN_OUT, " mm)"));
echo(str("MANTIS | magnets at +/-", W/2 - magnet_inset, " mm, skin ", magnet_skin,
         " mm | screws M", screw_diameter, " x 16 at +/-", W/2 - screw_inset, " mm"));
