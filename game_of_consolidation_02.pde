import processing.dxf.*;

//requires you to install the triangulation library from the processing wiki
import org.processing.wiki.triangulate.*;

//this is a class for an instance of a cell object
class Cell {
  PVector locale;
  PVector nextLocale;
  float radius;
  boolean draw;

  Cell(int x, int y) {
    this.locale = new PVector(x, y);
    this.draw = true;
  }
}
//points and tris are array lists needed for triangulation later
ArrayList points = new ArrayList();
ArrayList tris = new ArrayList();

//width and height. this determines the size of your grid.
int w = 512;
int h = 512;
//how much spacing do you want between cells?
int spacingw = 30;
//right now height is the same as width (square grid)
int spacingh = spacingw;

//max distance to draw a line between cells - deprecated
float drawMax = spacingw*4;

//change this to true if you want to output dxf
boolean dxfer = false;

//make the blank cell array
Cell[] cell;

//initial radius for the "cell" circles
float rad = (spacingw+spacingh)/6;

//how much space between cells warrants one cell eating another
float tolerance = (spacingw+spacingh)/2.15;

void setup() {

  if (dxfer) {
    size(w, h, P3D);
  }
  else {
    size(w, h);
  }

  background(248);
  fill(8);
  stroke(8);
  smooth();

  //based on spacing, how many columns will we need to make?
  int ccount = int(w/spacingw);

  //count the rows
  int rcount = int(h/spacingh);
  //println(rcount);

  //count the total number of cells
  int num = ccount * rcount;

  //use this number now to define the size of our cell array
  cell = new Cell[num];

  //set up the random location for each cell within its grid box
  int q = 0;
  for (int i=0; i < rcount; i++) {
    for ( int j=0; j <ccount; j++) {
      int x = j * spacingw;
      int y = i * spacingh;
      //random offset for X and Y within the grid box
      x += random(spacingw)-(spacingw/2);
      y += random(spacingh)-(spacingh/2);
      x += spacingw/2;
      y += spacingh/2;
      cell[q] = new Cell(x, y);
      cell[q].radius = rad;
      q++;
    }
  }
  //run the consolidate functions
  consolidate();
  consolidateTwo();
  if (dxfer) {
    beginRaw(DXF, "consump" + int(random(255)) + ".dxf");
  }

  //this will draw the geometry
  drawCells();
  drawTris();
  if (dxfer) {
    endRaw();
    println("dxf written");
  }
  //drawLines();
}

void draw() {
  //press the mouse button to save out a jpg frame
  if (mousePressed) {
    save("consump" + frameCount + ".jpg");
  }
}

//this function runs a single round of consolidation/consumption
void consolidate() {
  //sort them
  for (int i = 0; i < cell.length; i++) {
    for (int j = i+1; j < cell.length; j++) {
      //calculate the distance between any two cells
      float d = PVector.dist(cell[i].locale, cell[j].locale);

      //if its within a certain range then consolidate and grow
      if (d<tolerance && d!=0) {
        PVector midp = new PVector((cell[i].locale.x+cell[j].locale.x)/2, (cell[i].locale.y+cell[j].locale.y)/2); 
        cell[i].locale.set(cell[j].locale.x, cell[j].locale.y);
        cell[i].radius *= 1.15;
        cell[j].radius *= 1.15;
      }
    }
  }
}

//function for drawing cells as circles
void drawCells() {
  for (int i = 0; i < cell.length; i++) {
    if (cell[i].draw) {
      ellipse(cell[i].locale.x, cell[i].locale.y, cell[i].radius, cell[i].radius);
    }
  }
}


//another round of consolidation
void consolidateTwo() {
  for (int i = 0; i < cell.length; i++) {
    for (int j = i+1; j < cell.length; j++) {
      float d = abs(PVector.dist(cell[i].locale, cell[j].locale));
      //if the cell compared is within the radius then change it's draw status
      if (d < cell[i].radius + cell[j].radius) {
        if (cell[i].radius>=cell[j].radius) {
          cell[j].draw = false;
        }
        else {
          cell[i].draw = false;
        }
      }
    } 
    //ellipse(cell[i].locale.x, cell[i].locale.y, cell[i].radius, cell[i].radius);
  }
}

//draw lines between cells - deprecated
void drawLines() {
  strokeWeight(.3);
  for (int i = 0; i < cell.length; i++) {
    for (int j = i+1; j < cell.length; j++) {
      float d = abs(PVector.dist(cell[i].locale, cell[j].locale));
      if (d < drawMax) {
        if (cell[j].draw && cell[i].draw && cell[j].radius >= rad) {
          line(cell[i].locale.x, cell[i].locale.y, cell[j].locale.x, cell[j].locale.y);
        }
      }
    }
  }
}

//use the triangulate library to draw each triangle in the network
void drawTris() {
  for (int i=0; i<cell.length; i++) {
    if (cell[i].draw) {
      points.add(new PVector(cell[i].locale.x, cell[i].locale.y));
    }
  } 
  tris = Triangulate.triangulate(points);


  noFill();
  strokeWeight(rad/3);
  for (int i = 0; i < tris.size(); i++) {
    Triangle t = (Triangle)tris.get(i);
    line(t.p1.x, t.p1.y, t.p2.x, t.p2.y);
    line(t.p2.x, t.p2.y, t.p3.x, t.p3.y);
    line(t.p3.x, t.p3.y, t.p1.x, t.p1.y);
  }
}

