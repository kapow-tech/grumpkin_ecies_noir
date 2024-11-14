mod curves;  // Declare the module

pub struct Point {
    x: Field,
    y: Field
}

// Grumpkin generator (base point)
global G_x = Field(1);
global G_y = Field("17631683881184975370165255887551781615748388533673675138860");
pub global G = Point { x: G_x, y: G_y };  // Make G public for external modules

pub fn scalar_mul(k: Field, p: Point) -> Point {
    let mut result = Point { x: Field(0), y: Field(0) };  // Start at the identity point
    let mut base = p;
    let mut scalar = k;

    while scalar != Field(0) {
        if scalar & Field(1) == Field(1) {
            result = point_add(result, base);
        }
        base = point_double(base);  // Double the base point
        scalar = scalar >> Field(1);  // Right shift scalar
    }

    result
}

// Point addition
pub fn point_add(p: Point, q: Point) -> Point {
    if p == q {
        return point_double(p);  // If points are the same, use doubling
    }

    let s = (q.y - p.y) * (q.x - p.x).inverse();  // Slope for addition
    let x_r = s * s - p.x - q.x;  // New x-coordinate
    let y_r = s * (p.x - x_r) - p.y;  // New y-coordinate
    Point { x: x_r, y: y_r }
}

// Point doubling
pub fn point_double(p: Point) -> Point {
    let s = (3 * p.x * p.x) * (2 * p.y).inverse();  // Slope for doubling
    let x_r = s * s - 2 * p.x;  // New x-coordinate
    let y_r = s * (p.x - x_r) - p.y;  // New y-coordinate
    Point { x: x_r, y: y_r }
}