/*
	lab04part1.sv
*/
	
/* ------------------------------------------------------------------------ */
/* type definitions ------------------------------------------------------- */
/* ------------------------------------------------------------------------ */
	
typedef struct {
	real x;
	real y;
} point_st;
	
/* ------------------------------------------------------------------------ */
/* parameters ------------------------------------------------------------- */
/* ------------------------------------------------------------------------ */
	
parameter PI = 3.14;
	
/* ------------------------------------------------------------------------ */
/* global functions ------------------------------------------------------- */
/* ------------------------------------------------------------------------ */
	
/* get_distance() - calculate distance between points */
function real get_distance(point_st point0, point_st point1);
	real distance;
	distance = ((point0.x - point1.x)**2 + (point0.y - point1.y)**2)**0.5;
	return distance;
endfunction : get_distance
	
/* abs_real() - calculate abs for real values */
function real abs_real(real value);
	if (value < 0) return -value;
	else return value;
endfunction : abs_real
	
/* ------------------------------------------------------------------------ */
/* class definitions ------------------------------------------------------ */
/* ------------------------------------------------------------------------ */
	
virtual class shape_c;
		
	/* members */
	protected string name;
	protected point_st points[$];
		
	/* constructor */
	function new(string n, point_st p[$]);
		name = n;
		points = p;
	endfunction : new
		
	/* get_area() - calculate area - to be implemented in derived class */
	pure virtual function real get_area();
		
	/* print() - print name, points and calculated area */
	function void print();
			
		real area = get_area();
			
		$display("--------------------------------------------------------------------------------");
		$display("This is: %s", name);
		foreach (points[i]) begin
			$display("\t (%0.2f, %0.2f)", points[i].x, points[i].y);
		end
		if (area >= 0.0) $display("Area is: %0.2f", area);
		else $display("Area is: can not be calculated for generic polygon");
			
	endfunction : print
		
endclass : shape_c
	
class polygon_c extends shape_c;
		
	/* constructor */
	function new(string name, point_st points[$]);
		super.new(name, points);
	endfunction : new
		
	/* get_area() - calculate area */
	function real get_area();
		/* area can not be calculated for generic polygon */
		return -1.0;
	endfunction : get_area
		
endclass : polygon_c
	
class circle_c extends shape_c;
		
	/* constructor */
	function new(string name, point_st points[$]);
		super.new(name, points);
	endfunction : new
	
	/* print() - print name, points and calculated area */
	function void print();
			
		real radius = get_distance(points[0], points[1]);
		real area = get_area();
			
		$display("--------------------------------------------------------------------------------");
		$display("This is: %s", name);
		$display("\t (%0.2f, %0.2f)", points[0].x, points[0].y);
		$display("\t radius: %0.2f", radius);
		if (area >= 0.0) $display("Area is: %0.2f", area);
		else $display("Area is: can not be calculated for generic polygon");
			
	endfunction : print
	
	/* get_area() - calculate area */
	function real get_area();
		real radius = get_distance(points[0], points[1]);
		return (PI * radius**2);
	endfunction : get_area
	
endclass : circle_c
	
class rectangle_c extends polygon_c;
		
	/* constructor */
	function new(string name, point_st points[$]);
		super.new(name, points);
	endfunction : new
		
	/* get_area() - calculate area */
	function real get_area();
		real side1_len = get_distance(points[0], points[1]);
		real side2_len = get_distance(points[1], points[2]);
			
		return side1_len * side2_len;
	endfunction : get_area
		
endclass : rectangle_c
	
class triangle_c extends polygon_c;
		
	/* constructor */
	function new(string name, point_st points[$]);
		super.new(name, points);
	endfunction : new
		
	/* get_area() - calculate area */
	function real get_area();
		return abs_real(
			(points[1].x - points[0].x) * (points[2].y - points[0].y) -
			(points[2].x - points[0].x) * (points[1].y - points[0].y)
		) * 0.5;	
	endfunction : get_area
		
endclass : triangle_c
	
class shape_factory;
		
	static function shape_c make_shape(string name, point_st points[$]);
		circle_c	circle_h;
		polygon_c	polygon_h;
		rectangle_c	rectangle_h;
		triangle_c	triangle_h;
			
		case (name)
			"circle" : begin
				circle_h = new(name, points);
				return circle_h;
			end
				
			"polygon" : begin
				polygon_h = new(name, points);
				return polygon_h;
			end
				
			"rectangle" : begin
				rectangle_h = new(name, points);
				return rectangle_h;
			end
			
			"triangle" : begin
				triangle_h = new(name, points);
				return triangle_h;
			end
		endcase // case (name)
			
	endfunction : make_shape
		
endclass : shape_factory
	
class shape_reporter #(type T=shape_c);
		
	protected static T shape_storage [$];
		
	static function void store_shape(T l);
		shape_storage.push_back(l);
	endfunction : store_shape
		
	static function void report_shapes();
		foreach (shape_storage[i])
			shape_storage[i].print();
	endfunction : report_shapes
		
endclass : shape_reporter
	
/* ------------------------------------------------------------------------ */
/* top -------------------------------------------------------------------- */
/* ------------------------------------------------------------------------ */
	
module top;
		
	/* variables */
	int file;
	int r;
	string line;
	string temp_string = "";
	int j = 0;
	point_st temp_point;
	point_st points[$];
		
	initial begin
		/* shapes handlers */
		shape_c		shape_h;
		circle_c	circle_h;
		polygon_c	polygon_h;
		rectangle_c	rectangle_h;
		triangle_c	triangle_h;
			
		/* open file for reading */
		file = $fopen("/student/ksawosz/VDIC/lab04_part1/tb/lab04part1_shapes.txt", "r");
		if (file == 0) begin
			$display("Cannot open the file!");
			$finish;
		end
			
		/* read points from file */
		while (!$feof(file)) begin
			r = $fgets(line, file);
			if (r != 0) begin
				points.delete();
				j = 0;
				foreach (line[n]) begin
					if (line[n] != " " && line[n] != 10) begin
						temp_string = {temp_string,line[n]};
					end
					else if (line[n] == " " || line[n] == 10) begin
						if (j % 2 == 0) begin
							temp_point.x = temp_string.atoreal();
						end
						else begin
							temp_point.y = temp_string.atoreal();
							points.push_back(temp_point);
						end
						j++;
						temp_string = "";
					end
				end
				
				/* generate shape */
				case (points.size())
					2 : begin
						/* create circle */
						if (!$cast(circle_h, shape_factory::make_shape("circle", points)))
							$fatal(1, "Failed to cast shape from factory to circle_h");
						shape_reporter#(circle_c)::store_shape(circle_h);
					end
						
					3 : begin
						/* create triangle */
						if (!$cast(triangle_h, shape_factory::make_shape("triangle", points)))
							$fatal(1, "Failed to cast shape from factory to triangle_h");
						shape_reporter#(triangle_c)::store_shape(triangle_h);
					end
						
					4 : begin
						/* check if rectangle */
						automatic real side_len			= get_distance(points[0], points[2]);
						automatic real opposed_side_len	= get_distance(points[1], points[3]);
						if (side_len == opposed_side_len) begin
							/* create rectangle */
							if (!$cast(rectangle_h, shape_factory::make_shape("rectangle", points)))
								$fatal(1, "Failed to cast shape from factory to rectangle_h");
							shape_reporter#(rectangle_c)::store_shape(rectangle_h);
						end
						else begin
							/* create polygon */
							if (!$cast(polygon_h, shape_factory::make_shape("polygon", points)))
								$fatal(1, "Failed to cast shape from factory to polygon_h");
							shape_reporter#(polygon_c)::store_shape(polygon_h);
						end
					end
						
					default : begin
						/* create polygon */
						if (!$cast(polygon_h, shape_factory::make_shape("polygon", points)))
							$fatal(1, "Failed to cast shape from factory to polygon_h");
						shape_reporter#(polygon_c)::store_shape(polygon_h);
					end								
				endcase // (points.size())
			end
		end
			
		/* close the file */
		$fclose(file);
			
		/* report shapes */
		shape_reporter#(circle_c)::report_shapes();
		shape_reporter#(triangle_c)::report_shapes();
		shape_reporter#(rectangle_c)::report_shapes();
		shape_reporter#(polygon_c)::report_shapes();
			
		$display("\n");
	end
		
endmodule : top
