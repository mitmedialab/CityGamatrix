/**
* Name: GamaMatrix
* Author:  Arnaud Grignard
* Description: This is a template for the CityMatrix importation in GAMA. The user has the choice to instantiate the grid either from a local file ( onlineGrid = false) or from the cityscope server ( onlineGrid = true)
* The grid is by default loaded only once but it can be loaded every "refresh" cycle by setting (dynamicGrid= true).
* Tags:  grid, load_file, json
* Residential (0:L, 1:M, 2: S) 
* Office: (L:3, M:4, S: 5) - Road: 6 - Parking/Green Area : -1
*/

model GamaMatrix   

global {
	
	geometry shape <- square(1 #km);
	
    map<string, unknown> matrixData;
    map<int,rgb> buildingColors <-[0::rgb(189,183,107), 1::rgb(189,183,107), 2::rgb(189,183,107),3::rgb(230,230,230), 4::rgb(230,230,230), 5::rgb(230,230,230),6::rgb(40,40,40)];
    list<map<string, int>> cells;
	list<float> density_array;
	
	bool onlineGrid <- true parameter: "Online Grid:" category: "Grid";
	bool dynamicGrid <- true parameter: "Update Grid:" category: "Grid";
	int refresh <- 1000 min: 1 max:1000 parameter: "Refresh rate (cycle):" category: "Grid";
	bool surround <- true parameter: "Surrounding Road:" category: "Grid";
	bool looping <- false parameter: "Continuous Demo:" category: "Environment";
	int matrix_size <- 18;
	string filename <- './../includes/cityIO.json';
	bool first <- true;
	
	init {
        do initGrid;
	}
	
	action initGrid{
		if(onlineGrid = true){
		  matrixData <- json_file("http://cityscope.media.mit.edu/citymatrix_ml.json").contents;
	    }
	    else{
	      matrixData <- json_file(filename).contents;
	    }	
		cells <- matrixData["grid"];
		//density_array <- matrixData["objects"]["density"];
		density_array <- [30.0, 20.0, 10.0, 25.0, 15.0, 5.0];
		int a <- (matrix_size = 18) ? 1 : 0;
		loop c over: cells {
			int x <- 15 - c["x"] + a;
			int y <- c["y"] + a;               
            cityMatrix cell <- cityMatrix grid_at { 15 - c["x"] + a, c["y"] + a};
            if (! first and c["type"] = cell.type) {
            	// Same type on update - don't change color.
            } else {
            	if (int(c["type"]) = 7) {
            		// Camera  boy edge case. Assume park.
            		cell.type <- -1;
            	} else {
            		cell.type <- int(c["type"]);
            	}
            	cell.color <- (cell.type = -1) ? # gray : buildingColors[cell.type];
            }
            cell.density <- (cell.type = -1 or cell.type= 6) ? 0.0 : density_array[cell.type];
        }
	}
	
	reflex updateGrid when: ((cycle mod refresh) = 0) and (dynamicGrid = true) {
		first <- false;	
		do initGrid;
	}
}

grid cityMatrix width:matrix_size height:matrix_size {
	int type;
	rgb color;
	float density;
	
	aspect flat{
	  draw shape color:color border:#black;		
	}
	
    aspect base{
	  draw shape color:color depth:density * 2 border:#black;		
	}
}

experiment Display  type: gui {
	output {
		display cityMatrixView  type:opengl  background:#black {	
			overlay position: { 0, 0 } size: { 150 #px, 75 #px }   border: #black rounded: true
			{
               draw "CityGamatrix" color: # white font: font("Helvetica", 20, #bold) at: { 0, 20};
               draw "PEV Fleet" color: # white font: font("Helvetica", 14, #italic) at: { 100, 20};
            }
			species cityMatrix aspect:base;
		}
	}
}