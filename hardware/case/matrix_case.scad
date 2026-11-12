// MAX7219 16x64 desk enclosure with removable square-pixel grid and acrylic.
// LED/module pitch is configurable. Confirm alignment with grid_test before printing.
// Read README.md before printing. All individual parts are oriented for printing.
// Preview includes translucent reference blocks; these are never exported as solids.
// Revision: internal 0.15 mm separator removed; optical stack bears on the front bezel.
// Revision: staggered rear-lid joint cross-fastens the two existing body halves.

/* [Choose a part] */
part = "assembly"; // [assembly,body,lid,body_left,body_right,lid_left,lid_right,foot,keys,fit_test,pixel_grid,grid_left,grid_right,grid_test,skin_grid,skin_grid_left,skin_grid_right]
/* [Measured display] */
matrix_width = 264; // Confirmed overall width
matrix_height = 64; // Confirmed overall height
pcb_width = 264; // Retention-pad positions only; inspect against the real PCB
pcb_height = 64;
matrix_depth = 13;
connector_extra = 5;
/* [Fit] */
side_clearance = 0.4; // Each side of the display
front_lip = 0.6; // Overlap of the display perimeter; check with fit_test
front_thickness = 2;
wall = 3.2;
rim = 7; // Top and bottom rims accommodate enclosure screws
body_depth = 40; // Excludes rear cover
lid_thickness = 2.4;
/* [Rear lid joint] */
lid_seam_offset = 18; // Left lid reaches across upper centre screws, right across lower
lid_seam_step_y = 10;
lid_seam_clearance = 0.25; // Total gap between the two lid pieces
split_lid_preview = true;
/* [Optional square pixel optics] */
optics_enabled = true; // false removes the added optical depth and side cover
acrylic_thickness = 2;
slide_clearance = 0.35; // Total allowance in depth, per insert
grid_depth = 4;
grid_wall = 0.5; // Print in opaque black; use a suitable small extrusion width
module_gap_x = 1.5;
module_gap_y = 1;
// Inferred LED pitches: measured outer dimensions take priority over approximate block size.
// Override these if you later measure the LED centres directly. Test before full printing.
pixel_pitch_x = (matrix_width-7*module_gap_x)/64;
pixel_pitch_y = (matrix_height-module_gap_y)/16;
module_pitch_x = 8*pixel_pitch_x+module_gap_x;
module_pitch_y = 8*pixel_pitch_y+module_gap_y;
pixel_offset_x = 0; // Active area's centre relative to PCB centre
pixel_offset_y = 0;
led_gap = 0.15; // Nominal depth allowance only; no internal separator or fixed LED gap
/* [Display retention] */
retention_pads = true;
pad_edge_inset = 2.5; // From PCB edges to pad centre; inspect component clearance
pad_size = 3;
pad_rigid_gap = 1.5; // Add 2 mm soft insulating foam at each tip
/* [ESP32 and desk feet] */
esp_x = 60; // Position of adhesive mounting platform on rear cover
esp_platform_width = 22;
esp_platform_height = 28;
desk_tilt = 0;
foot_width = 16;
foot_clearance = 0.6; // Total clearance across enclosure thickness
/* [Hidden] */
$fn = 40;
eps = 0.02;
cw = matrix_width + 2*side_clearance;
ch = matrix_height + 2*side_clearance;
ow = cw + 2*wall;
oh = ch + 2*rim;
slot_depth = acrylic_thickness + grid_depth + 2*slide_clearance;
optics_extra = optics_enabled ? slot_depth + led_gap : 0;
matrix_z = front_thickness + optics_extra;
pocket_start_z = optics_enabled ? front_thickness : matrix_z;
actual_body_depth = body_depth + optics_extra;
total_depth = actual_body_depth + lid_thickness;
grid_z = front_thickness + acrylic_thickness + 1.5*slide_clearance;
cap_thickness = 2;
cap_fit = 0.15;
cap_depth = actual_body_depth-front_thickness;
cell_opening = min(pixel_pitch_x,pixel_pitch_y)-grid_wall;
echo("Acrylic cut size mm", [matrix_width,matrix_height,acrylic_thickness]);
echo("Outer dimensions mm", [ow,oh,total_depth]);
assert(grid_wall > 0 && grid_wall < min(pixel_pitch_x,pixel_pitch_y), "Invalid grid wall");
assert(7*module_pitch_x+8*pixel_pitch_x+2*abs(pixel_offset_x) <= matrix_width+eps, "Module spacing exceeds display envelope: check measurements");
assert(module_pitch_y+8*pixel_pitch_y+2*abs(pixel_offset_y) <= matrix_height+eps, "Module spacing exceeds display envelope: check measurements");
assert(led_gap >= 0 && slide_clearance > 0, "Invalid optics clearance");
screw_y = ch/2 + rim/2;
screw_x = [ -ow/2+7, -9, 9, ow/2-7 ];
pilot_d = 2.7;
pilot_depth = 9;
key_length = 16;
key_width = 3;
key_height = 5;
key_clearance = 0.25; // Per side; glue the keys
key_z = [12,24];
pad_reach = body_depth - front_thickness - matrix_depth - pad_rigid_gap;
assert(front_lip > 0 && front_lip < 2, "Use a small front lip to avoid covering LEDs");
assert(body_depth > front_thickness+matrix_depth+connector_extra+12,
       "Increase body_depth to leave wiring/ESP space");
assert(rim >= 6, "Top/bottom rims must accommodate screws");
assert(abs(esp_x)+esp_platform_width/2+5 < cw/2, "ESP platform outside cavity");

module screw_points() {
    for(x=screw_x, y=[-screw_y,screw_y]) translate([x,y,0]) children();
}

module body(split_sockets=false) {
    difference() {
        translate([-ow/2,-oh/2,0]) cube([ow,oh,actual_body_depth]);
        // One continuous pocket: no unsupported separator behind the optical stack.
        // With optics disabled, the normal 2 mm front bezel retains the display.
        translate([-cw/2,-ch/2,pocket_start_z]) cube([cw,ch,actual_body_depth+eps]);
        translate([-matrix_width/2+front_lip,-matrix_height/2+front_lip,-eps])
            cube([matrix_width-2*front_lip,matrix_height-2*front_lip,matrix_z+2*eps]);
        screw_points() translate([0,0,actual_body_depth-pilot_depth])
            cylinder(d=pilot_d,h=pilot_depth+eps);
        if(optics_enabled) {
        }
        // Vents through the top wall, with short bridges.
        for(x=[-49:7:49]) translate([x-1.5,ch/2-eps,25+optics_extra])
            cube([3,rim+2*eps,8]);
        // Four blind alignment sockets at the split seam.
        if(split_sockets) for(y=[-screw_y,screw_y], z=key_z)
            translate([-key_length/2-key_clearance,y-key_width/2-key_clearance,z-key_height/2-key_clearance])
                cube([key_length+2*key_clearance,key_width+2*key_clearance,key_height+2*key_clearance]);
    }
}

// Lid in print coordinates: outside surface on bed; inside faces upward.
module lid() {
    difference() {
        union() {
            translate([-ow/2,-oh/2,0]) cube([ow,oh,lid_thickness]);
            // Flat surface for insulating foam tape: board is strapped or taped here.
            translate([esp_x-esp_platform_width/2,-esp_platform_height/2,lid_thickness-eps])
                cube([esp_platform_width,esp_platform_height,1.2+eps]);
            if(retention_pads)
                for(x=[-pcb_width/2+pad_edge_inset,pcb_width/2-pad_edge_inset],
                    y=[-pcb_height/2+pad_edge_inset,pcb_height/2-pad_edge_inset])
                    translate([x-pad_size/2,y-pad_size/2,lid_thickness-eps])
                        cube([pad_size,pad_size,pad_reach+eps]);
        }
        screw_points() translate([0,0,-eps]) cylinder(d=3.4,h=lid_thickness+2*eps);
        // Cable/plug access, rather than a socket-specific USB cutout.
        translate([esp_x-11,17,-eps]) cube([22,12,lid_thickness+2*eps]);
        // Tie slots on both sides of the ESP platform.
        for(x=[esp_x-esp_platform_width/2-3,esp_x+esp_platform_width/2+3],y=[-8,8])
            translate([x-1.5,y-3,-eps]) cube([3,6,lid_thickness+2*eps]);
        for(x=[-95:7:-39]) translate([x-1.5,-12,-eps]) cube([3,24,lid_thickness+2*eps]);
    }
}

// Assembly orientation: front z=0, rear z=total_depth; y is display height.
module assembled_lid() {
    translate([0,0,total_depth]) mirror([0,0,1])
        if(split_lid_preview) {
            lid_piece("left");
            lid_piece("right");
        } else lid();
}

// Three-step seam. Upper left and lower right tongues cross the body joint.
// Both pieces use existing screw holes; no body modifications are required.
module lid_left_outline() {
    polygon([[-ow,-oh],[-lid_seam_offset,-oh],
             [-lid_seam_offset,-lid_seam_step_y],[0,-lid_seam_step_y],
             [0,lid_seam_step_y],[lid_seam_offset,lid_seam_step_y],
             [lid_seam_offset,oh],[-ow,oh]]);
}

module lid_piece(which) {
    assert(lid_seam_offset > 9+3.4/2+3, "Give the crossed centre screw enough surrounding plastic");
    assert(lid_seam_offset < cw/2-20, "Lid overlap too large");
    assert(lid_seam_step_y > 2 && lid_seam_step_y < screw_y-5, "Keep seam steps away from screw holes");
    assert(lid_seam_clearance > 0 && lid_seam_clearance < 1, "Invalid seam clearance");
    intersection() {
        lid();
        translate([0,0,-eps]) linear_extrude(height=lid_thickness+pad_reach+2*eps)
            offset(delta=-lid_seam_clearance/2)
                if(which=="left") lid_left_outline();
                else rotate(180) lid_left_outline();
    }
}

module half(which) {
    intersection() {
        children();
        translate([which=="left" ? -ow/2-1 : 0,-oh/2-1,-1])
            cube([ow/2+1,oh+2,100]);
    }
}

module keys() {
    for(i=[0:3]) translate([i*(key_length+4),0,0]) cube([key_length,key_width,key_height]);
}

// Side profile lies on bed. Slot tilts the display backward by desk_tilt.
// Low front jaw stays below the LED aperture; tall rear jaw supports the back.
module foot() {
    depth = total_depth+foot_clearance;
    back = 18+depth*cos(desk_tilt)+24;
    linear_extrude(height=foot_width)
        difference() {
            polygon([[0,0],[back,0],[back-10,32],[18+depth-3,32],[15,16],[0,16]]);
            translate([18,12]) rotate(-desk_tilt) translate([0,-eps]) square([depth,60]);
        }
}

// Regular 64 x 16 array: all interior dividers are grid_wall wide.
// Cell pitch is 4.125 x 4 mm for the confirmed 264 x 64 mm panel.
module regular_grid(columns=64,rows=16) {
    px=matrix_width/64;
    py=matrix_height/16;
    w=columns*px;
    h=rows*py;
    difference() {
        translate([-w/2,-h/2,0]) cube([w,h,grid_depth]);
        intersection() {
            translate([-w/2+grid_wall,-h/2+grid_wall,-eps])
                cube([w-2*grid_wall,h-2*grid_wall,grid_depth+2*eps]);
            union() for(c=[0:columns-1],r=[0:rows-1])
                translate([(c-columns/2)*px+grid_wall/2,
                           (r-rows/2)*py+grid_wall/2,-eps])
                    cube([px-grid_wall,py-grid_wall,grid_depth+2*eps]);
        }
    }
}
module pixel_grid() { regular_grid(); }
module grid_test() { regular_grid(16,16); }

module display_reference() {
    color([0.16,0.16,0.18,0.65])
        translate([-matrix_width/2,-matrix_height/2,matrix_z])
            cube([matrix_width,matrix_height,matrix_depth]);
    color([0.1,0.6,0.2,0.6])
        translate([esp_x-9,-12,total_depth-lid_thickness-7]) cube([18,24,4]);
}

module assembly() {
    // Transform enclosure into the same desk coordinates as the feet.
    // Foot profile x is desk depth; y is height; extrusion z is display width.
    color("#364552")
        translate([0,18,12]) rotate([-desk_tilt,0,0])
            multmatrix([[1,0,0,0],[0,0,1,0],[0,1,0,0],[0,0,0,1]])
            translate([0,oh/2,0]) {
                body();
                color("#647380") assembled_lid();
                if(optics_enabled) {
                    color("#151515") translate([0,0,grid_z]) pixel_grid();

                    %color([0.8,0.9,1,0.25])
                        translate([-matrix_width/2,-matrix_height/2,front_thickness+slide_clearance/2])
                            cube([matrix_width,matrix_height,acrylic_thickness]);
                }
                %display_reference();
            }
    for(x=[-ow*0.30,ow*0.30])
        color("#27343e") translate([x-foot_width/2,0,0])
            multmatrix([[0,0,1,0],[1,0,0,0],[0,1,0,0],[0,0,0,1]]) foot();
}

if(part=="body") body();
else if(part=="lid") lid();
else if(part=="body_left") half("left") body(true);
else if(part=="body_right") half("right") body(true);
else if(part=="lid_left") lid_piece("left");
else if(part=="lid_right") lid_piece("right");
else if(part=="foot") foot();
else if(part=="keys") keys();
else if(part=="skin_grid") { pixel_grid(); translate([-matrix_width/2,-matrix_height/2,0]) cube([matrix_width,matrix_height,0.4]); }
else if(part=="skin_grid_left") half("left") { pixel_grid(); translate([-matrix_width/2,-matrix_height/2,0]) cube([matrix_width,matrix_height,0.4]); }
else if(part=="skin_grid_right") half("right") { pixel_grid(); translate([-matrix_width/2,-matrix_height/2,0]) cube([matrix_width,matrix_height,0.4]); }
else if(part=="pixel_grid") pixel_grid();
else if(part=="grid_left") half("left") pixel_grid();
else if(part=="grid_right") half("right") pixel_grid();
else if(part=="grid_test") grid_test();
else if(part=="fit_test") intersection() {
    body();
    translate([-ow/2-1,-oh/2-1,-eps]) cube([23,oh+2,22]);
}
else if(part=="assembly") assembly();
else assert(false,"Unknown part");
