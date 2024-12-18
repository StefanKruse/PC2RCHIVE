PC2RCHIVE application

This application was built in R Studio using the shiny package.
The following packages related to shiny were also used to build the program: shinythemes, fresh, shinyFiles, htmltools, markdown.

Files required in the application must be in the same directory as the application:
-'general_information.txt' - text of the landing page ('General information' tab)
-'references.txt' - list of references that is included in the final report ('maps.Rmd', 'maps_forPDF.Rmd')
R markdown (Rmd) files to create reports:
-'reading_las.Rmd', 'reading_las_forPDF.Rmd'
-'elevation_models.Rmd', 'elevation_models_forPDF.Rmd'
-'tree_segmentation.Rmd', 'tree_segmentation_forPDF.Rmd'
-'maps.Rmd', 'maps_forPDF.Rmd'

Tabs:
1. General information

The landing page describes the main functionalities of the application and lists the main references (the complete list of references is in the report).
Text is read in from file 'general_information.txt'.

2. Reading point cloud data

2.1 Determine the path to the parent directory:
- Browser: if browsing is slow, click the black arrows to open the inner directories and wait until they appear.
- Typing in: since the browser may be slow, the user can type the path in the input field.

2.2 Create new plot folder in parent directory
This folder is zipped at the end of data processing.

2.3 Browse point cloud to process

2.4 Save point cloud into the new plot folder

2.5 Create two tables with general information about the point cloud

2.6 Create report
Add the name of data processor and the date to the input fields.
Download reports as both HTML and PDF files into the plot folder under the suggested name ('reading_las').
Note: the final report is compiled from multiple report segments downloaded at the end of each data processing step.
To create the reports the following R packages were used: htmltools, markdown, knitr, tinytex, pdftools

3. Data processing

3.1 Ground classification
The user can select among three possibilities:

3.1.1 Use classification from the loaded point cloud
The point cloud may already contain classification that the user wants to use.
3.1.1.1 The layer containing the classification has to be specified ('Layer of classes'). The program checks if the layer exists.
3.1.1.2 The ground and canopy classes are selected
3.1.1.3 The classes are visualized with the plots appearing in pop-up windows
3.1.1.4 A table is created containing ground and above-ground points
3.1.1.5 Save data - lidR package 
- Point cloud is saved again under the name 'plotName_ground_classification.laz'
- Ground points are saved as 'plotName_groundonly.laz'
- Above-ground points are saved as 'plotName_aboveground.laz'
- Table of ground and above-ground points is saved as 'plotName_classification_number_of_points_per_class.csv'

3.1.2 Upload classified data
The user wants to upload a new file with the classification to use.
3.1.2.1 The layer containing the classification has to be specified ('Layer of classes'). The program checks if the layer exists.
3.1.2.2 The ground and canopy classes are selected
3.1.2.3 The classes are visualized on plots appearing in pop-up windows
3.1.2.4 A table is created containing ground and above-ground points
3.1.2.5 Save data - lidR package to write LAZ files
- Point cloud is saved again under the name 'plotName_ground_classification.laz'
- Ground points are saved as 'plotName_groundonly.laz'
- Above-ground points are saved as 'plotName_aboveground.laz'
- Table of ground and above-ground points is saved as 'plotName_classification_number_of_points_per_class.csv'

3.1.3 Classify data using Cloth simulation filter (CSF) - lidR and RCSF packages
The user wants to classify the points of the cloud in the application using the CSF.
CSF (Zhang et al., 2016) is a morphological filter that fits a surface (like a cloth) on the bottom of the ground. Adjusting the filter parameters such as rigidness, cloth resolution and classification threshold allows finding an optimal fit.
3.1.3.1 Filter parameters are selected
A short description of the three parameters and the values used in previous classifications (see: Brieger et al., 2019) are included in the program. 
3.1.3.2 Run classification: the classes are visualized on plots appearing in pop-up windows
3.1.3.3 A table is created containing ground and above-ground points
3.1.3.4 Save data - lidR package to write LAZ files
- Point cloud is saved again under the name 'plotName_ground_classification.laz'
- Ground points are saved as 'plotName_groundonly.laz'
- Above-ground points are saved as 'plotName_aboveground.laz'
- Table of ground and above-ground points is saved as 'plotName_classification_number_of_points_per_class.csv'

3.2 Digital Terrain Model (DTM) - lidR package
Digital Terrain Model (DTM) represents the ground level without any vegetation. Here a local minimum moving filter is applied to shift the terrain level below the lower vegetation. DTM is also smoothed to mitigate the effect of microtopography. 
3.2.1 Resolution of DTM is selected (meter scale)
3.2.2 DTM is generated and plotted

3.3 Digital Surface Model (DSM) - lidR package
Digital Surface Model (DSM) is created based on the highest points of all surface objects (vegetation included) and so it is calculated by interpolating the highest points of each grid cell.
3.3.1 DSM is generated (same resolution as by DTM) and plotted

3.4 Canopy Height Model (CHM) - lidR package
Canopy Height Model (CHM) is the vegetation thickness derived from the difference between DSM and DTM.
3.4.1 CHM is generated (same resolution as by DTM/DSM) and plotted

3.5 Slope and aspect of DTM - terra package
3.5.1 Slope and aspect are generated (same resolution as by DTM/DSM) and plotted

3.6 
3.6.1 Save files - terra package to write rasters
- DTM, DSM, CHM, slope, aspect are saved as TIFF files under the names 'plotName_DTM.tif, 'plotName_DSM.tif, 'plotName_CHM.tif, 'plotName_slope.tif, 'plotName_aspect.tif
3.6.2 Download reports for section 3. as HTML and PDF into the plot folder under the suggested name ('elevation_models').


4. Individual tree segmentation

4.1 Tree detection

4.1.1 At this point the data processing can be interrupted and picked up later on. Before going on with tree detection, the user has to set the path of parent directory and updTE the name of the plot folder on site 'Reading point cloud data'.

4.1.2 Select linear function for dynamic window size function from the list
When the user selects 'other', they have to option to define the function themselves.
4.1.3 Determine minimum tree height parameter for tree detection function
4.1.4 Find tree tops positions and determine crown polygons - ForestTools package
For the tree detection a dynamic circular moving local maximum filter is used, which is based on the selected linear function. The tree tops are the highest pixels in the search radius. The method considers that large trees usually have larger crowns.  
The algorithm that is used to calculate the crown diameter is similar to that used for watershed segmentation in hydrological analysis. The CHM is inverted and the trees are handled as valleys.
In the next step, the detected tree tops are assigned to the crown polygons and the identified trees get an ID number.
A plot is generated to test the input parameters. - tmap package
4.1.5 Tree tops without crown polygons get deleted and a final plot is generated. - tmap package
4.1.6 Save data - sf package to write shape files
- tree top positions and crown polygons are saved as shape files into a subfolder within the plot folder called 'plotName_crownsPoly'
- table of parameters (linear function and minimum tree height) is saved as 'plotName_tree_segmentation_parameters.csv'

4.2 Create point cloud of trees
4.2.1 Generate point cloud of tree points only. - lidR package to read LAZ files
4.2.2 Save files - lidR package to write LAZ files
Tree IDs are added to the above-ground point cloud as well.
- Tree points are saved as 'plotName_treesonly.laz'
- Above-ground points are resaved with IDs as 'plotName_aboveground.laz'
- Table of ground and tree points is saved as 'plotName_classification_number_of_points_per_class2.csv'

4.3 Tree statistics 
4.3.1 Histogram and density plot of tree height is created - ggplot2 and egg packages
4.3.2 Table of tree statistics is created including min/max/mean tree height and mean crown diameter - units package
4.3.3 Table of tree statistics is saved as 'plotName_tree_statistics_table.csv'
4.3.4 Download reports for section 4. as HTML and PDF into the plot folder under the suggested name ('tree_segmentation').

5. Maps

5.1 Footprint
5.1.1 At this point the data processing can be interrupted and picked up later on. Before going on with maps, the user has to set the path of parent directory and the name of plot folder on site 'Reading point cloud data'.
5.1.2 Footprint is created based on CHM (aggregated, no NA values) in both UTM and long/lat coordinates (WGS84, EPSG:4326) - terra and sf packages 
5.1.3 Footprints (UTM and long/lat) are saved as shape files into a subfolder within the plot folder called 'plotName_footprint'

5.2 UTM map
5.2.1 UTM map is created with the footprint - tmap, tmaptools, OpenStreetMap and sf packages
The UTM map includes the footprint and the bounding box coordinates of footprint in long/lat form.
5.2.2 Use the map buffer input field to change the size of the map (e.g if the numbers of long/lat coordinates are out of the map)

5.3 Interactive map 
5.3.1 Interactive map is generated with the footprint - leaflet, webshot and mapview packages 
5.3.2 Download mapshot of interactive map into PNG files
These images are inserted into the PDF report.
Save the images into the plot folder under the suggested name: 'plotName_OpenStreetMap_footprint.png' and 'plotName_ESRI_footprint.png'
5.3.3 Download reports
5.3.3.1 HTML report is compiled from previous report segments and saved under name:
'Report_plotName.html.
The report contains an interactive map.
5.3.3.2 PDF report of maps is saved separately ('maps') and then the summary PDF is created from all the fragments ('reeport_plotName.pdf')

6. User provided metadata

6.1 Contributors -  DT package
The user provides information on the contributors: names and tasks. Additional comments can be made.
Browse a table or create a new one by submitting a contributor.
The table can be edited, saved and reloaded later to add more information.
The table of contributors belong to the whole campaign and is mostly not plot-specific.
Table is saved into the parent directory under a selected name.

6.2 Summary table with user provided metadata - DT package 
The user provides metadata related to the data acquisition and the point cloud generation. Besides the metadata, parameters and results of the data processing progress are all collected into a summary table.
Since multiple point clouds are created from the remote sensing data collected during a campaign, every point cloud has its own row in the summary table.
Browse a table or create a new one by adding a new row. The table can be edited, saved and reloaded later to add more information.
Table is saved into the parent directory under a selected name.

Comments on some metadata:
- Event: ID assigned by shipping??
- Date and time of data collection: Finding out the date: look for raw files (EMLID/EMLIDreach) that have the date and time of recording in their names.
- Mode of ground classification: select how data was classified
- Please add any additional information on data classification: if user used a pre-classified data, they should give more information on it

7. Zip files
The generated output data of every point cloud from the campaign is zipped into separate folders.
7.1 List the folders to be zipped
7.2 Zip the folders - utils package


Acknowledgements
This project has been supported by the DataHub Information Infrastructure funds, projects BorFIT and PC2RCHIVE. 











