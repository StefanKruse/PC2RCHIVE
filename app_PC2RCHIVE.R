## created by Luca Zsofia Farkas
## 07.2024
## PC2RCHIVE project

library(shiny)
library(shinythemes)
library(fresh)
library(shinyFiles) 

library(htmltools) 
library(markdown)
library(knitr)
library(tinytex)
library(pdftools)

library(lidR) 
library(RCSF)
library(concaveman)

library(tidyverse)
library(dplyr)
library(raster)
library(terra)
library(sf)
library(units)

library(ggplot2)
library(egg)

library(leaflet)
library(mapview)
library(webshot)

library(tmap)
library(tmaptools)
library(OpenStreetMap)

library(ForestTools)
library(DT)

library(utils)


################################
## Define user interface (UI) ##
################################

ui <- fluidPage(theme = shinytheme("united"), 
                #### theme, color ####
                navbarPage("PC2RCHIVE", id="PC2RCHIVE", header = tagList(use_theme(create_theme(
                  theme = "default",
                  bs_vars_navbar(default_bg = "darkgreen",
                                 default_color = "#FFFFFF",
                                 default_link_color = "#FFFFFF",
                                 default_link_active_color = "darkgreen",
                                 default_link_active_bg = "#FFFFFF",
                                 default_link_hover_color = "firebrick"),
                  bs_vars_button(default_color = "#FFF",
                                 default_bg = "darkgreen",
                                 default_border = "#FFF",
                                 primary_color = "darkgreen",
                                 primary_bg = "#FFF",
                                 primary_border = "darkgreen",
                                 border_radius_base = 0), output_file = NULL 
                ))),
                ##### tabPanel1 - general info ####
                tabPanel("General information", value = "tabPanel1",# tabPanel1
                         mainPanel(
                           uiOutput("htmlfile"), 
                           column(width=12 ,align="right",
                                  actionButton("jumpToTabPanel2", "Jump to next page", class="btn-xs", type="info")),
                           br(),
                           br()
                         )),
                ##### tabPanel2 - reading las####
                tabPanel("Reading point cloud data", value = "tabPanel2", # tabPanel2,
                         wellPanel(
                           h4("Select parent directory"),
                           h5("This folder contains the plot folders of a measurement campaign."),
                           br(),
                           checkboxGroupInput("outputfolder_selection", "Select one:",                
                                              c("Browse" = "v1_output",
                                                "Type in" = "v2_output")),
                           conditionalPanel(condition = "input.outputfolder_selection == 'v1_output'",
                                            h5("Click on the black arrows to open up directories. Loading data takes time..."),
                                            shinyDirButton('outputfolder', 'Browse...', title = "Please select a folder", multiple=FALSE),
                                            h5("Wait for path to show up..."),
                                            verbatimTextOutput("outputfolder_dir")
                           ),
                           conditionalPanel(condition = "input.outputfolder_selection == 'v2_output'",
                                            textInput("outputfolder_typed", h5("Path of directory"), "N:/"),
                                            actionButton("select_typed_folder", "Select"),
                                            textOutput("outputfolder_dir_typed")
                                            ),
                         ),
                         wellPanel(
                           textInput("plotName", h4("Plot name"), width = "25%", "EN22019"),
                           h5("Create a folder for the new plot in the parent directory."),
                           h5("This folder is zipped at the end."),
                           actionButton("create_folder_for_plot", "Generate new folder")
                         ),
                         wellPanel(
                           #fileInput("readLas", h4("Select LAZ file"), accept = c("las", "laz")),
                           h4("Select point cloud data (LAZ file)"),
                           shinyFilesButton("input_laz", 'Browse...', title = "Please select a file", multiple=FALSE, filetype=c('las','laz')),
                           verbatimTextOutput("inputfile_path"),
                           h4("Save point cloud to plot folder"),
                           actionButton("save_las", "Save file"),
                         ),
                         wellPanel(
                           h4("Create table with point cloud statistics"),
                           actionButton("create_summary", "Create table"),
                           br(),
                           tableOutput("RawSummary1"),
                           tableOutput("RawSummary2"),
                           tableOutput("RawSummary3")
                         ),
                         wellPanel(
                           h4("Create table with point cloud information"),
                           actionButton("generate_table_with_point_cloud_info", "Create table"),
                           br(),
                           tableOutput("pointCloudInfo"),
                           h5("Save relevant data for later use:"),
                           actionButton("save_table_data", "Save")
                         ),
                         wellPanel(
                           h4(checkboxInput("trajectory_available", "Trajectory file is available")),
                           conditionalPanel(condition = "input.trajectory_available == 1",
                                            h5("Select trajectory"),
                                            shinyFilesButton("input_trajectory", 'Browse...', title = "Please select a file", multiple=FALSE, filetype=c('txt')),
                                            verbatimTextOutput("input_trajectory_path"),
                                            h5("Save file to output folder"),
                                            actionButton("save_trajectory", "Save as text file"),
                                            br(),
                                            h5("Add UTM zone number based on data in previous table"),
                                            numericInput("utmZone","UTM zone number", width = "25%", 54),
                                            h5("Create hull around trajectory"),
                                            h6("Relative measure of concavity"),
                                            h6("Select parameter: 2 or 3 for most of the plots work well. 1 results in a relatively detailed shape."),
                                            numericInput("concavity", "Concavity", width = "25%", 2),
                                            actionButton("create_traj_hull", "Create hull"),
                                            plotOutput("trajectory_hull"),
                                            h5("Add buffer and save files"),
                                            actionButton("save_traj", "Save files"))
                         ),
                         wellPanel(
                           h4(checkboxInput("clip_point_cloud", "Clip point cloud based on trajectory (with 20 m buffer)")),
                           conditionalPanel(condition = "input.clip_point_cloud == 1",
                             actionButton("clip_pc", "Clip"),
                             h5("Save file by overwriting the unclipped point cloud in the new plot folder"),
                             actionButton("save_clipped_pc", "Save"),
                             h6("At this point cloud data should be reloaded: load 'plotName'_point_cloud.laz from the plot folder. Tables should be regenerated as well.")
                           ),
                         ),
                         wellPanel(
                           h4("Report"),
                           textInput("dataProc_person", "Name of data processor", width = "25%", ""),
                           dateInput("dataProc_date", "Date of data processing", width = "25%", ""),
                           h5(strong("Download report")),
                           h5("Please save the file under the suggested name in the plot folder!"),
                           downloadButton("download_report1", "Download as HTML"),
                           downloadButton("download_report1_pdf", "Download as PDF"),
                           h5("Note: the final report is compiled from the segments downloaded at the end of each data processing step."),
                         br(),
                         br(),
                         br(),
                         fluidRow(
                           column(width=12 ,align="right",
                                  actionButton("jumpToTabPanel3", "Jump to next page", class="btn-xs", type="info"))
                         ),
                         br(),
                         br(),
                         ),
                         ),
                ##### tabPanel3 - ground classification ####
                tabPanel("Data processing", value = "tabPanel3",
                         tabsetPanel(id="data_processing",
                                     tabPanel("Ground classification", value = "tabPanel3_1",
                                              wellPanel(
                                                h4("Classification"),
                                              checkboxGroupInput("classification_selection", "Select one:",
                                                                 c("Use classification from the loaded point cloud" = "v1",
                                                                   "Upload classified data" = "v2",
                                                                   "Classify data - Cloth Simulation Filter" = "v3")),
                                              ),
                                              #### conditionalPanel - v1 ####
                                              conditionalPanel(condition = "input.classification_selection == 'v1'",
                                                               wellPanel(
                                                                 h4("Classification in point cloud"),
                                                                 h5("Select layer of classified data:"),
                                                                 textInput("layer_class_v1", "Layer of classes",  width = "25%", "Classification"),
                                                                 h5("Check if layer exists"),
                                                                 actionButton("check_layer_v1", "Check layer"),
                                                                 verbatimTextOutput("output_check_layer_v1"),
                                                                 h4("Create ground and canopy models"),
                                                                 h5("Select classes defining ground/canopy"),
                                                                 fluidRow(
                                                                   column(width=3, offset=0, numericInput("ground_class_v1", "Class of ground points", 2)),
                                                                   column(width=3, offset=0, selectInput("aboveground_class_v1", "Class of above-ground points", choices = list("Every class except for the ground class", "Select class"))),
                                                                   conditionalPanel(condition = "input.aboveground_class_v1 == 'Select class'",
                                                                                    column(width=3, numericInput("canopy_class_v1", "Class of above-ground points", 1))),
                                                                   ),
                                                                 h4("Classification - number of points"),
                                                                 actionButton("create_table_pointNo_v1", "Create table"),
                                                                 tableOutput("pointData_v1"),
                                                                 h5("Point clouds are generated from ground and above-ground points."),
                                                                 h5("Note: Creating plots is optional."),
                                                                 actionButton("submit_classes_v1", "Create plots"),
                                                                 plotOutput("ground_plot_v1"),
                                                                 plotOutput("tree_plot_v1"),
                                                                 h4("Save classified data to the earlier selected directory"),
                                                                 actionButton("save_classified_data_v1", "Save"),
                                                               )),
                                              #### conditionalPanel - v2 ####
                                              conditionalPanel(condition = "input.classification_selection == 'v2'",
                                                               wellPanel(
                                                                 h4("Select classified data if available"),
                                                                 shinyFilesButton("input_classified", 'Browse...', title = "Please select a file", multiple=FALSE, filetype=c('las','laz')),
                                                                 verbatimTextOutput("input_classified_path"),
                                                                 h5("Select layer of classified data:"),
                                                                 textInput("layer_class_v2", "Layer of classes",  width = "25%", "Classification"),
                                                                 h5("Check if layer exists"),
                                                                 actionButton("check_layer_v2", "Check layer"),
                                                                 verbatimTextOutput("output_check_layer_v2"),
                                                                 h4("Create gound and canopy models"),
                                                                 h5("Select classes defining ground/canopy"),
                                                                 fluidRow(
                                                                   column(width=3, offset=0, numericInput("ground_class_v2", "Ground class", 2)),
                                                                   column(width=3, offset=0, selectInput("aboveground_class_v2", "Class of above-ground points", choices = list("Every class except for the ground class", "Select class"))),
                                                                   conditionalPanel(condition = "input.aboveground_class_v2 == 'Select class'",
                                                                                    column(width=3, numericInput("canopy_class_v2", "Class of above-ground points", 1))),
                                                                 ),
                                                                 h4("Classification - number of points"),
                                                                 actionButton("create_table_pointNo_v2", "Create table"),
                                                                 tableOutput("pointData_v2"),
                                                                 h5("Point clouds are generated from ground and above-ground points."),
                                                                 h5("Note: Creating plots is optional."),
                                                                 actionButton("submit_classes_v2", "Create plots"),
                                                                 plotOutput("ground_plot_v2"),
                                                                 plotOutput("tree_plot_v2"),
                                                                 h4("Save preclassified data to output directory"),
                                                                 actionButton("save_preclassified_data_v2", "Save"),
                                                               )),
                                              #### conditionalPanel - v3 ####
                                              conditionalPanel(condition = "input.classification_selection == 'v3'",
                                                               wellPanel(
                                                                 h4("Classify data using CSF"),
                                                                 h4("Filter parameters"),
                                                                 h5("Parameter description is taken from F. Brieger's Masterthesis (2019)"),
                                                                 h5(strong("Classification threshold (m)")),
                                                                 h5("The maximum distance between the cloth and a point to be classified as ground."),
                                                                 h5("Values used: 0.1/0.2/0.3"),
                                                                 h5(strong("Cloth resolution (m)")),
                                                                 h5("Sets the cloth’s cell size: set to a value that ensures flexibility for following the micro-topography, while not being smaller than the inner diameter of the high, hollow vegetation bodies."),
                                                                 h5("Values used: 0.1/0.2"),
                                                                 h5(strong("Rigidness")),
                                                                 h5("First order stiffness of the cloth."),
                                                                 h5("Values used: 1 - flat scenes, 2 - minor relief, 3 - steep slopes"),
                                                                 fluidRow(
                                                                   column(width=4, offset=0, numericInput("classThreshold", "Classification threshold", 0.5)),
                                                                   column(width=4, offset=0, numericInput("clothResolution", "Cloth resolution", 0.5)),
                                                                   column(width=4, offset=0, numericInput("rigidness", "Rigidness", 1L)),
                                                                 ),
                                                                 actionButton("run_classification","Run"),
                                                                 h4("Classification - number of points"),
                                                                 tableOutput("pointData_v3"),
                                                                 h5("Point clouds are generated from ground and above-ground points."),
                                                                 h5("Note: Creating plots is optional."),
                                                                 actionButton("submit_classes_v3", "Create plots"),
                                                                 plotOutput("ground_plot_v3"),
                                                                 plotOutput("tree_plot_v3"),
                                                                 h4("Save classified data to the earlier selected directory"),
                                                                 actionButton("save_classified_data_v3", "Save"),
                                                                 )),
                                              fluidRow(
                                                column(width=12 ,align="right",
                                                       actionButton("jumpToTabPanel3_2", "Jump to next page", class="btn-xs", type="info"))
                                              ),
                                              br(),
                                              br()
                                     ),
                                     #### DTM, DSM, CHM, slope and aspect ####
                                     tabPanel("Digital Terrain Model", value = "tabPanel3_2",
                                              sidebarPanel(h4("Create Digital Terrain Model"),
                                                           h5("Parameters"),
                                                           numericInput("resolution_DEM", "Resolution", 0.1), #The size of a grid cell in  point cloud coordinates units.
                                                           actionButton("generateDTM", "Generate"),
                                                           h5("If the size of the point cloud is so big, that the computer runs out of memory, R is aborted."),
                                                           h5("To solve this issue, the user can create DTM out of the Shiny application and save the file into the plot folder under the name: plotName_DTM.tif. The application automatically reads in existing DTM files."),
                                                           h5("NOTE: Therefore, if the user wants to generate a new DTM they should be sure that a previous version is not saved into the plot folder!"),
                                                           br(),
                                                           h5("The user can also generate DTM by dividing the point cloud into two parts (with 10% overlap) and so creating DTMs by the two halves separately. The two DTMs are merged to get the final DTM (mean is calculated at the overlapping area)."),
                                                           checkboxInput("dtm_version2", "Generate DTM in two steps"),
                                                           h5("Do NOT tick the box if the statement is not true!"),
                                                           conditionalPanel(condition = "input.dtm_version2 == 1",
                                                                            actionButton("generateDTM_v2", "Generate")),
                                                           ),
                                              mainPanel(h5(strong("DTM")),
                                                        plotOutput("DTM"),
                                                        plotOutput("DTM_v2")),
                                              fluidRow(
                                                column(width=12 ,align="right",
                                                       actionButton("jumpToTabPanel3_3", "Jump to next page", class="btn-xs", type="info"))
                                              ),
                                              br(),
                                              br(),
                                     ),
                                     tabPanel("Digital Surface Model", value = "tabPanel3_3",
                                              sidebarPanel(h4("Create Digital Surface Model"),
                                                           h5("Same resolution as for DTM."),
                                                           actionButton("generateDSM", "Generate"),
                                                           br(),
                                                           h5("The user can create DSM out of the Shiny application and save the file into the plot folder under the name: plotName_DSM.tif. The application automatically reads in existing DSM files. Therefore, if the user wants to generate a new DSM they should be sure that a previous version is not saved into the plot folder!"),
                                                           ),
                                              mainPanel(h5(strong("DSM")),
                                                        plotOutput("DSM")),
                                              fluidRow(
                                                column(width=12 ,align="right",
                                                       actionButton("jumpToTabPanel3_4", "Jump to next page", class="btn-xs", type="info"))
                                              ),
                                              br(),
                                              br(),
                                     ),
                                     tabPanel("Canpoy Height Model",  value = "tabPanel3_4",
                                              sidebarPanel(h4("Create Canpoy Height Model"),
                                                           h5("Same resolution as for DTM and DSM."),
                                                           actionButton("generateCHM", "Generate")),
                                              mainPanel(h5(strong("CHM")),
                                                        plotOutput("CHM")),
                                              fluidRow(
                                                column(width=12 ,align="right",
                                                       actionButton("jumpToTabPanel3_5", "Jump to next page", class="btn-xs", type="info"))
                                              ),
                                              br(),
                                              br(),
                                     ),
                                     tabPanel("Slope and aspect", value = "tabPanel3_5",
                                              sidebarPanel(
                                                h4("Calculate slope of DTM"),
                                                h5("Same resolution as for DTM."),
                                                actionButton("generateSlope", "Generate"),
                                                h4("Calculate aspect of DTM"),
                                                h5("Same resolution as for DTM."),
                                                actionButton("generateAspect", "Generate"),
                                              ),
                                              mainPanel(
                                                h5(strong("Slope")),
                                                plotOutput("slope_plot"),
                                                br(),
                                                h5(strong("Aspect")),
                                                plotOutput("aspect_plot")
                                              ),
                                              fluidRow(
                                                column(width=12 ,align="right",
                                                       actionButton("jumpToTabPanel3_6", "Jump to next page", class="btn-xs", type="info"))
                                              ),
                                              br(),
                                              br(),
                                     ),
                                     tabPanel("Save files", value = "tabPanel3_6",
                                              wellPanel(
                                                h4("Save files"),
                                                h5("Save DTM, DSM, CHM, slope and aspect as TIFF files"),
                                                actionButton("save_raster_files", "Save all files"),
                                                br(),
                                                h4("Download report"),
                                                h5("Please save the file under the suggested name in the plot folder!"),
                                                downloadButton("download_report2", "Download as HTML"),
                                                downloadButton("download_report2_pdf", "Download as PDF")
                                              ),
                                              column(width=12 ,align="right",
                                                     actionButton("jumpToTabPanel4", "Jump to next page", class="btn-xs", type="info")),
                                              br(),
                                              br()
                                     )
                         )
                ), # tabPanel3
                ##### tabPanel4 - tree detection #####
                tabPanel("Individual tree segmentation", value = "tabPanel4",
                         tabsetPanel(id = "indiv_tree_segm",
                                     tabPanel("Tree detection", value = "tabPanel4_1",
                                          wellPanel(
                                            h5(strong("Data processing has been interrupted")),h5("If R has crashed or work has been interrupted, data processing can be continued from here. For that the previous steps should be completed and the generated data saved!"),
                                            h5("1. Select output directory and update plot name in panel 'Reading point cloud data'"),            
                                            h5("2. Load point cloud with ground classification, if the file is not loaded in the program (created during Ground classification):"),
                                            checkboxInput("reload_PC_cl", "Reload point cloud with ground classification"),
                                            conditionalPanel(condition = "input.reload_PC_cl == 1",
                                                            ),
                                            h5("Do NOT tick the box if the statement is not true!"), 
                                            h5("3. Start individual tree segmentation")
                                            ), # wellPanel
                                          sidebarPanel(width = 5,
                                            h4("Select function to detect individual trees"),
                                            h6("The linear functions determine the search radius that is dependent on the pixel height x."),
                                            h6("The function affects the number and position of treetops."),
                                            h6("Generally a narrower function works better to differentiate between closely spaced trees. (Brieger et al., 2019)"),
                                            h6("function(x){x * 0.045 + 0.8} - Small, widely spaced trees"),
                                            h6("function(x){x * 0.020 + 0.6} - Narrow and tall trees"),
                                            h6("function(x){x * 0.020 + 0.4} - Tall trees"),
                                            h6("function(x){x * 0.035 + 0.05} - Narrow, closely spaced and small/medium-sized trees"),
                                            br(),
                                            selectInput("lin_function", "Linear function for dynamic circular moving local maximum filter",
                                                    choices = list("function(x){x * 0.045 + 0.8}",
                                                                   "function(x){x * 0.020 + 0.8}",
                                                                   "function(x){x * 0.020 + 0.6}",
                                                                   "function(x){x * 0.020 + 0.4}",
                                                                   "function(x){x * 0.035 + 0.05}",
                                                                   "other")),
                                            conditionalPanel(condition = "input.lin_function == 'other'",
                                                             textInput("lin_function_manual", "Select linear function:", "function(x){x * 0.020 + 0.8}")),
                                            br(),
                                            numericInput("minHeight", "Minimum tree height", 0.4),
                                            h5("Test linear function and tree height parameters:"),
                                            actionButton("submit_treePoly_map", "Generate test plot"),
                                            h5("Filter out tree tops without crown polygon:"),
                                            actionButton("submit_treePoly_map_2", "Generate plot"),
                                            br(),
                                            h4("Save files"),
                                            h5("Save shape files of tree top positions and crown polygons"),
                                            h5("Save table of the used parameters"),
                                            actionButton("save_tree_shapefiles", "Save files"),
                                          ), # sidebarPanel
                                          mainPanel(width = 7,
                                            h5(strong("Crown polygons with tree tops - first version")),
                                            plotOutput("crownPoly_treeTops"),
                                            h5(strong("Crown polygons with tree tops - final version")),
                                            plotOutput("crownPoly_treeTops_filt"),
                                          ), # mainPanel
                                          fluidRow(
                                            column(width=12 ,align="right",
                                                   actionButton("jumpToTabPanel4_2", "Jump to next page", class="btn-xs", type="info"))
                                          ),
                                          br(),
                                          br()
                           ), # tabPanel4_1
                           tabPanel("Creating point cloud of trees", value = "tabPanel4_2",
                                    sidebarPanel(
                                      h4("Generate point cloud from tree points only"),
                                      actionButton("generate_treesonly_laz", "Generate file"),
                                      br(),
                                      h4("Visualization"),
                                      h5("Note: if the point cloud is too big (lidar LAZ file is >1,3 GB) visualization can fail. In that case skip visualization and directly save the data."),
                                      actionButton("plot_treesonly_laz", "Create plot"),
                                      br(),
                                      br(),
                                      h4("Save files"),
                                      h5("Save table with number of tree points"),
                                      h5("Save tree points in a new LAZ file"),
                                      h5("Add tree ID-s to existing LAZ file with above-ground points only"),
                                      h5("Add tree ID-s to existing LAZ file with ground classification"),
                                      br(),
                                      br(),
                                      actionButton("save_treesOnly_laz_file", "Save files"),
                                    ),
                                    mainPanel(
                                      h5(strong("Plot")),
                                      plotOutput("tree_plot_v4"),
                                      h5(strong("Number of tree points")),
                                      tableOutput("pointData_v4"),
                                    ),
                                    fluidRow(
                                      column(width=12 ,align="right",
                                             actionButton("jumpToTabPanel4_3", "Jump to next page", class="btn-xs", type="info"))
                                    ),
                                    br(),
                                    br(),
                            ), #tabPanel4_2
                           tabPanel("Tree statistics", value = "tabPanel4_3",
                                    sidebarPanel(
                                      h4("Histogram and density plot of tree height"),
                                      actionButton("create_hist", "Create"),
                                      br(),
                                      br(),
                                      h4("Table of tree statistics"),
                                      actionButton("tree_statistics", "Creat table"),
                                      br(),
                                      br(),
                                      h4("Save data"),
                                      h5("Save table of statistics"),
                                      actionButton("save_tree_segm_csvs", "Save"),
                                      br(),
                                      br(),
                                      h4("Download report"),
                                      h5("Please save the file under the suggested name in the plot folder!"),
                                      downloadButton("download_report3", "Download as HTML"),
                                      downloadButton("download_report3_pdf", "Download as PDF")
                                    ), # sidebarPanel
                                    mainPanel(
                                      h5(strong("Histogram and density plot of tree height")),
                                      plotOutput("hist_treeH"),
                                      br(),
                                      h5(strong("Table of tree statistics")),
                                      tableOutput("tree_statistics_table"),
                                      column(width=12 ,align="right",
                                              actionButton("jumpToTabPanel5", "Jump to next page", class="btn-xs", type="info")),
                                      br(),
                                      br()
                                    ) # mainPanel
                           ) # tabPanel4_3
                          ) # tabsetPanel
                ), # tabPanel4
                ##### tabPanel5 - map #####
                tabPanel("Maps", value = "tabPanel5", # tabPanel5
                         tabsetPanel(id = "maps_and_report",
                                     tabPanel("Footprint", value = "tabPanel5_1",
                                              wellPanel(
                                                  h5(strong("Data processing has been interrupted")),
                                                  h5("If R has crashed or work has been interrupted, data processing can be continued from here. For that the previous steps should be completed and the generated data saved!"),
                                                  h5("1. Select output directory and update plot name in panel 'Reading point cloud data'"),
                                                  h5("2. Start creating maps")
                                              ), # wellPanel
                                              sidebarPanel(
                                                  h4("Footprint of point cloud"),
                                                  actionButton("create_footprint", "Create footprint"),
                                                  br(),
                                                  br(),
                                                  h4("Save footprint as shape file"),
                                                  h5("Data is saved in both LongLat and UTM coordinates."),
                                                  actionButton("save_footprint", "Save"),
                                              ), # sidebarPanel
                                              mainPanel(
                                                  h5(strong("Footprint")),
                                                  plotOutput("plot_boundary")
                                              ), # mainPanel
                                              fluidRow(
                                                column(width=12 ,align="right",
                                                       actionButton("jumpToTabPanel5_2", "Jump to next page", class="btn-xs", type="info"))
                                              ),
                                              br(),
                                              br()
                                     ), # tabPanel5_1
                                     tabPanel("UTM map", value = "tabPanel5_2",
                                       sidebarPanel(
                                         h4("Create UTM map"),
                                         actionButton("generate_map", "Generate"),
                                         h5("Setting to change the size of area around the footprint:"),
                                         numericInput("extent_buffer", h5(strong("Map buffer")), 0.009),
                                       ), # sidebarPanel
                                       mainPanel(
                                         h5(strong("Footprint on map (UTM coordinates)")),
                                         plotOutput("footprint_map", width = "700px", height = "700px"),
                                       ), # mainPanel
                                       fluidRow(
                                         column(width=12 ,align="right",
                                                actionButton("jumpToTabPanel5_3", "Jump to next page", class="btn-xs", type="info"))
                                       ),
                                       br(),
                                       br()
                                     ), # tabPanel5_2
                                     tabPanel("Interactive map", value = "tabPanel5_3",
                                       sidebarPanel(
                                         h4("Create interactive map (Long-Lat)"),
                                         actionButton("generate_interactive_map", "Generate"),
                                         br(),
                                         br(),
                                         h4("Save images for PDF report"),
                                         h5("HTML report will contain interactive maps."),
                                         h5("Download footprint on OpenStreetMap"),
                                         downloadButton(outputId = "downloadData_osm", "Download image - OSM"),
                                         h5("Download footprint on ESRI Imagery"),
                                         downloadButton(outputId = "downloadData_esri", "Download image - ESRI"),
                                         br(),
                                         br(),
                                         h4("Download report"),
                                         h5("Please save the file under the suggested name in the plot folder!"),
                                         downloadButton("download_report4", "Download final HTML report"),
                                         br(),
                                         br(),
                                         downloadButton("download_report4_pdf", "Download maps as PDF"),
                                         br(),
                                         br(),
                                         actionButton("create_pdf_report", "Download final PDF report")
                                      ), # sidebarPanel
                                       mainPanel(
                                         h5(strong("Footprint on interactive map")),
                                         h6("Layers of Open Street Map and ESRI Imagery are available."),
                                         leafletOutput(outputId = "map"),
                                         br(),
                                         br()
                                       ), # mainPanel
                                       column(width=12 ,align="right",
                                          actionButton("jumpToTabPanel6", "Jump to next page", class="btn-xs", type="info")
                                       ),
                                      br(),
                                      br()
                                    ) # tabPanel5_3
                        ), # tabsetPanel
                ), # tabPanel
                ##### tabPanel6 - metadata ####
                tabPanel("User provided metadata", value = "tabPanel6", # tabPanel6
                         tabsetPanel(id="contributors_metadata",
                                     tabPanel("Contributors", value = "tabPanel6_1",
                                              wellPanel(
                           h4("Contributors"),
                           h5(strong("Select datatable to edit")),
                           fileInput("input_contributors", "Load table"),
                           fluidRow(
                             column(3, offset=0, textInput("contributor", "Name", "")),
                             column(3, offset=0, selectInput("contributor_function", "Task", 
                                                             choices = list("Conceptualization",
                                                                            "Mission planning",
                                                                            "Funding acquisition",
                                                                            "Project administration",
                                                                            "Supervision",
                                                                            "Resources",
                                                                            "Drone flight operation",
                                                                            "Field support",
                                                                            "Raw data processing",
                                                                            "Data processing",
                                                                            "Data processing/ Data curation",
                                                                            "Software",
                                                                            "Formal analysis",
                                                                            "Validation",
                                                                            "Other"))),
                             column(6, offset=0, textInput("comments", "Comments", ""))
                           ),
                           actionButton("submitbutton_contributors", "Submit contributors one-by-one"), 
                           actionButton("delete_last_row_contr", "Delete last row"),
                           actionButton("deleteRow_csv_contr", "Delete selected rows"),
                           h5(strong("Table of contributors")),
                           DTOutput("tabledata_contributors"),
                           h5(strong("Double-click on cells to edit their content")),
                           br(),
                           h5(strong("Save data")),
                           h5("Select original file and overwrite it or create a new file"),
                           downloadButton("download_contributors", "Save table (overwrite if existing)"),
                           fluidRow(
                             column(width=12 ,align="right",
                                    actionButton("jumpToTabPanel6_2", "Jump to next page", class="btn-xs", type="info"))
                           ),
                           br(),
                           br()
                         ) # wellPanel
                        ),# tabPanel6_1
                         tabPanel("Metadata", value = "tabPanel6_2",
                           wellPanel(
                           h4("Summary table with user provided metadata"),
                           h5(strong("Select datatable to edit")),
                           fileInput("input_mastertable", "Load table"),
                           br(),
                           h5(strong("Select new input data")),
                           textInput("eventName", "Event", "16-KP-01-EN18001"),
                           textInput("dateOfRecording", "Date and starting time of data collection", "yyyy-mm-dd hh:mm"),
                           h5("Finding out the date: look for raw files (EMLID/EMLIDreach) that have the date and time of recording in their names."),
                           textInput("additionalInfo", "Please add any additional information on data aquisition (e.g. weather):", ""),
                           fluidRow(
                             column(4, selectInput("device", "Device", choices = list("YellowScan Mapper+", "GreenValley Inc DGC50", "Phantom 4 RGB"))),
                           ),
                           fluidRow(
                             column(4, selectInput("colorization", "Colorization", choices = list("Yes", "No"))),
                           ),
                           fluidRow(
                             column(4, selectInput("software", "Software for preprocessing", choices = list("Agisoft Metashape", "CloudStation (by YellowScan)"))),
                           ),
                           fluidRow(
                             column(4, selectInput("strip_alignment", "Strip alignment", choices = list("Precise", "Robust"))),
                             column(4, numericInput("strip_aligment_error", "Strip aligment error", 1)),
                           ),
                           fluidRow(
                             column(4, selectInput("coord_proj_corr", "Coordinate projection correction", choices=list("POSPac PP-RTX", "Not available"))),
                             column(4, textInput("coord_proj_corr_reference_frame", "POSPac PP-RTX: Reference frame used", NA))
                           ),
                           fluidRow(
                             column(5, selectInput("classification_mode", "Mode of ground classification", choices=list("An existing classification from the point cloud was used",
                                                                                                                        "New classified data was uploaded",
                                                                                                                        "Data was classified using Cloth Simulation Filter"))),
                             column(7, textInput("extraInfoClassification", "Please add any additional information on data classification:", ""))
                           ),
                           h5("Note: to create the table, each output must be created and saved, and all maps must be loaded into the the 'Maps' panel"),
                           actionButton("addRow_csv", "Add new row"),
                           actionButton("deleteLastRow_csv", "Delete last row"),
                           actionButton("deleteRow_csv", "Delete selected rows"),
                           h5(strong("Metadata table")),
                           DTOutput("table_metadata"),
                           h5(strong("Double-click on cells to edit their content")),
                           br(),
                           h5(strong("Save data")),
                           h5("Select original file and overwrite it or create a new file"),
                           downloadButton("download_metadata", "Save table (overwrite if existing)")
                         ), # wellPanel
                         wellPanel(
                           h4("To process the next point cloud jump to the first panel:"),
                           actionButton("jumpToTheStart", "Jump to the beginning"),
                           h4("If all point clouds are processed jump to the next page to zip the files:"),
                           actionButton("jumpToTheEnd", "Jump to next page"),
                           br(),
                           br()
                         ) # wellPanel
                         ) # tabPanel6_2
                         ) # tabsetPanel
                ), # tabPanel6
                ##### tabPanel7 - zipping files ####
                tabPanel("Zip files", value = "tabPanel7", # tabPanel7
                         wellPanel(
                           h4("List of folders to zip"),
                           actionButton("list_folders", "List"),
                           htmlOutput("folder_list"),
                           h4("Zip every plot folder of the parent directory"),
                           actionButton("zip_folders", "Zip folders")
                         ))
                #####
                ) # end of navbarPage 
) # end of fluidPage


#############################
## Define server component ##
#############################

server <- function(input, output, session){
  
  ######### tabPanel1 - general info ####
  
  ## Render markdown file containing general information on the application
  
  output$htmlfile <- renderUI({
    includeMarkdown((knit('general_information.rmd', quiet = TRUE)))
  })
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel2, {
    updateTabsetPanel(session, "PC2RCHIVE", selected = "tabPanel2")
  })
  
  ######### tabPanel2 - reading las ####  
  
  ## Select output folder - conditionalPanel - v_1_output
  shinyDirChoose(input, 'outputfolder', roots = getVolumes()())
  outputfolder_selected <- eventReactive(input$outputfolder, {
    
    parseDirPath(getVolumes()(), input$outputfolder)
  })  
  output$outputfolder_dir <- renderText({
    as.character(outputfolder_selected())})
  
  ## Select output folder - conditionalPanel - v_2_output
  output_directory_v2 <- eventReactive(input$select_typed_folder, {
    if (input$outputfolder_selection == 'v2_output') {
      input$outputfolder_typed}
  })
  
  output$outputfolder_dir_typed <- renderText({
      if(req(input$select_typed_folder)){
        "Directory is selected."
      }
    })
  
  output_directory <- reactive({
    if(input$outputfolder_selection == 'v2_output') {
      output_directory_v2()
    } else if(input$outputfolder_selection == 'v1_output') {
      as.character(outputfolder_selected())
    }
  })
  
  
  ## Generate new folder for plot
  observeEvent(input$create_folder_for_plot, {
    if (!dir.exists(paste0(output_directory(), "/", input$plotName))) {
      dir.create(paste0(output_directory(), "/", input$plotName))}
  })
  
  ## Select input file
  shinyFileChoose(input, 'input_laz', roots = getVolumes()(), filetypes = c('','laz', 'las'))
  file_selected <- eventReactive(input$input_laz, {
    req(input$input_laz)
    parseFilePaths(getVolumes()(), input$input_laz)
  })
  
  ## Show path to input file
  output$inputfile_path <- renderText(as.character(file_selected()$datapath))
  
  ## Pathway to raw LAZ file
  path <- reactive({
    as.character(file_selected()$datapath)
  })
  
  ## Read in point cloud (LAZ file)
  raw <- reactive({
    
    id <- showNotification("Reading data...", duration = NULL, closeButton = FALSE) # create notification for user: https://mastering-shiny.org/action-feedback.html#transient-notification
    on.exit(removeNotification(id), add = TRUE)
    
    readLAS(path()) # raw point cloud in LAS format
  }) 
  
  ## Save point cloud to new folder
  observeEvent(input$save_las, {
    
    id <- showNotification("Saving file...", duration = NULL, closeButton = FALSE) # create notification for user: https://mastering-shiny.org/action-feedback.html#transient-notification
    on.exit(removeNotification(id), add = TRUE)
    
    writeLAS(raw(), paste0(output_directory(), "/", input$plotName , "/",input$plotName, "_point_cloud.laz"))
  })
  
  ## Create table with general information on the raw point cloud
  df_sum_tables_big <- eventReactive(input$create_summary, {
    cols <- colnames(raw()@data)
    
    id <- showNotification("Creating table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    lst <- unclass(raw()@data) # logical with NAs
    df_sum_tables_big <- data.frame(matrix(nrow=6, ncol=0))
    for (i in 1:end(cols)[1]) {
      df_sum_tables <- data.frame(t(summary(lst[[i]])))
      df_sum_tables <- df_sum_tables[,-c(1)]
      colnames(df_sum_tables) <- c(" ", cols[i])
      if (nrow(df_sum_tables)<6) {
        df_sum_tables[nrow(df_sum_tables)+(6-nrow(df_sum_tables)),] <- ""
      }
      df_sum_tables[is.na(df_sum_tables)] <- ""
      df_sum_tables_big <- cbind(df_sum_tables_big,df_sum_tables)
    } 
    df_sum_tables_big
  })
  
  ## Visualize table as three separate tables
     df_1 <- reactive({
       df_1 <- df_sum_tables_big()[,c(1:10)] #[,c(1:16)]
       colnames(df_1)[seq(1,9,2)] <- ""
       df_1
       })
      
    output$RawSummary1 <- renderTable({
      df_1()
    })
    
    df_2 <- reactive({
      df_2 <- df_sum_tables_big()[,c(11:20)] #[,c(17:32)]
      colnames(df_2)[seq(1,9,2)] <- ""
      df_2
      })
    
    output$RawSummary2 <- renderTable({
      df_2()
    })
    
    df_3 <- reactive({
      df_3 <- df_sum_tables_big()[,c(21:32)]
      colnames(df_3)[seq(1,11,2)] <- ""
      df_3
    })
    
    output$RawSummary3 <- renderTable({
      df_3()
    })
    
  ## Create second table with gerenal information on the raw point cloud 
  info_raw2 <- eventReactive(input$generate_table_with_point_cloud_info, {
    
    id <- showNotification("Creating table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if(!is.null(raw())){
      info_raw <- capture.output(print(raw()))
      data.frame(info_raw) 
    }
  })
  
  ## Render table
  output$pointCloudInfo <- renderTable({
    info_raw2()
  })
  
  ## Create table of area, number of points and point density
  raw_points <- reactive({
    raw_points <- data.frame(matrix(nrow=1, ncol=3))
    colnames(raw_points) <- c("Area", "Points", "Density")
    raw_points[1,1] <- sub('.*: ', '', info_raw2()[5,])
    raw_points[1,2] <- raw()@header$`Number of point records`
    raw_points[1,3] <- sub('.*: ', '', info_raw2()[7,])
    raw_points
  })
  
  ## Save table of area, number of points and point density
  observeEvent(input$save_table_data, {
    
    id <- showNotification("Saving data...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    write.csv(raw_points(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_point_cloud_area_point_density.csv"),
              row.names = F)
  })
  
  ## Add trajectory to output folder (if available)
  ## Select input file
  shinyFileChoose(input, 'input_trajectory', roots = getVolumes()(), filetypes = c('','txt'))
  trajectory_file_selected <- eventReactive(input$input_trajectory, {
    req(input$input_trajectory)
    parseFilePaths(getVolumes()(), input$input_trajectory)
  })
  ## Show path to input file
  output$input_trajectory_path <- renderText(as.character(trajectory_file_selected()$datapath))
  ## Save file
  observeEvent(input$save_trajectory, {
    file.copy(as.character(trajectory_file_selected()$datapath), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_trajectory.txt"))
  })
  
  ## Filter out the part of trajectory where data was recorded (based on point cloud GPS times)
  trajectory3 <- reactive({
    
    id <- showNotification("Create trajectory...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    trajectory <- read.csv(as.character(trajectory_file_selected()$datapath), header = T, sep = " ")
    trajectory2 <- trajectory[trajectory$Time>=min(raw()$gpstime),]
    trajectory2[trajectory2$Time<=max(raw()$gpstime),]
    })
  
  traj_coord_sf <- reactive({
    trajectory3() %>%
    st_as_sf(coords = c("X", "Y"), crs= 32600 + input$utmZone)
    })
  ## Generate hull around trajectory
  traj_hull <- eventReactive(input$create_traj_hull, {
    
    id <- showNotification("Create hull...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    concaveman(traj_coord_sf(), concavity = input$concavity, length_threshold = 0)
    }) 
  
  output$trajectory_hull <- renderPlot({
    if (!is.null(traj_hull())) {
      isolate(plot(traj_hull()))
    }
    })
  
  ## Create buffer
  buffer_10 <- reactive({st_buffer(traj_hull(), 10)})
  buffer_20 <- reactive({st_buffer(traj_hull(), 20)})

  ## Save files
  observeEvent(input$save_traj, {
    
    id <- showNotification("Saving data...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if (!dir.exists(paste0(output_directory(), "/", input$plotName , "/", input$plotName, "_trajectory"))) {
      dir.create(paste0(output_directory(), "/", input$plotName, "/", input$plotName, "_trajectory"))}
    
    st_write(traj_hull(), paste0(output_directory(), "/", input$plotName , "/", input$plotName, "_trajectory/", input$plotName, "_trajectory_hull.shp"), append=FALSE)
    st_write(buffer_10(), paste0(output_directory(), "/", input$plotName , "/", input$plotName, "_trajectory/", input$plotName, "_trajectory_with_10m_buffer.shp"), append=FALSE)
    st_write(buffer_20(), paste0(output_directory(), "/", input$plotName , "/", input$plotName, "_trajectory/", input$plotName, "_trajectory_with_20m_buffer.shp"), append=FALSE)
  })
  
  ## Clip and save point cloud if requested
  
  clipped_pc <- eventReactive(input$clip_pc, {
    
    id <- showNotification("Clipping point cloud...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    clip_roi(raw(), buffer_20())
  })
  
  observeEvent(input$save_clipped_pc, {
    
    id <- showNotification("Saving file...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    writeLAS(clipped_pc(), paste0(output_directory(), "/", input$plotName , "/",input$plotName, "_point_cloud.laz"))
  })
  
  
  ## Create report as HTML 
  output$download_report1 <- downloadHandler(
    filename = "reading_las.html",
    content = function(file) {
      
      id <- showNotification("Downloading report...", duration = NULL, closeButton = FALSE) # create notification for user: https://mastering-shiny.org/action-feedback.html#transient-notification
      on.exit(removeNotification(id), add = TRUE)
      
      res <- rmarkdown::render(
        "reading_las.Rmd",
        params = list(
          info_raw2 = info_raw2(), df_1 = df_1(), df_2 = df_2(), df_3 = df_3()
        )
      )
      file.rename(res, file)
    }
  )
  
  ## Create report as PDF 
  output$download_report1_pdf <- downloadHandler(
    filename = "reading_las.pdf",
    content = function(file) {
      
      id <- showNotification("Downloading report...", duration = NULL, closeButton = FALSE) # create notification for user: https://mastering-shiny.org/action-feedback.html#transient-notification
      on.exit(removeNotification(id), add = TRUE)
      
      res <- rmarkdown::render(
        "reading_las_forPDF.Rmd",
        params = list(
          info_raw2 = info_raw2(), df_1 = df_1(), df_2 = df_2(), df_3 = df_3()
        )
      )
      file.rename(res, file)
    }
  )
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel3, {
    updateTabsetPanel(session, "PC2RCHIVE", selected = "tabPanel3")
    updateTabsetPanel(session, "data_processing", selected = "tabPanel3_1")
  })
  
  ######### tabPanel3 - ground classification ####
  
  ## conditionalPanel - Classification in point cloud - "v1" ####
  
  ## Check if selected layer exists
  observeEvent(input$check_layer_v1, {
    test <- input$layer_class_v1
    if(!is.null(isolate({raw()$Classification}))) { 
      output$output_check_layer_v1 <- renderText({"Layer exists."})
    } else if(is.null(isolate({raw()$Classification}))) {
      output$output_check_layer_v1 <- renderText({"Layer doesn't exist."})
    }
    
  })
  
  ## Create table with number of points per class
  PointNo_table_v1 <- eventReactive(input$create_table_pointNo_v1, {
    
    id <- showNotification("Creating table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    PointNo_table_v1 <- data.frame(matrix(nrow = 2, ncol=2))
    colnames(PointNo_table_v1) <- c("Class", "Number of points")
    PointNo_table_v1[1,2] <- table(raw()@data$Classification)[[2]] # ground points
    PointNo_table_v1[1,1] <- "Ground"
    PointNo_table_v1[2,2] <- table(raw()@data$Classification)[[1]] # canopy points
    PointNo_table_v1[2,1] <- "Above ground"
    PointNo_table_v1
  })
  
  ## Render table
  output$pointData_v1 <- renderTable({
    PointNo_table_v1()
  })
  
  ### Create point clouds of ground and above-ground points
  
  ## Create point cloud of ground points
  
  gnd_v1 <- reactive({
    
    id <- showNotification("Creating point cloud of ground points...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    filter_poi(raw(), Classification==input$ground_class_v1)
  })
  
  tree_v1 <- reactive({
    if (input$aboveground_class_v1 == "Every class except for the ground class") {
      
      id <- showNotification("Creating point cloud of above-ground points...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      filter_poi(raw(), Classification!=input$ground_class_v1)
      
    } else if (input$aboveground_class_v1 == "Select class")  {
      
      id <- showNotification("Creating point cloud of above-ground points...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      filter_poi(raw(), Classification==input$canopy_class_v1)
    }
  })
  
  ## Plot ground point cloud
  output$ground_plot_v1 <- renderPlot({ # opened in a pop-up window
    
    id <- showNotification("Creating plot in pop-up window...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if(req(input$submit_classes_v1)) { 
      isolate(plot(gnd_v1(), size = 3, bg = "white"))
    }
  }) 
  
  ## Plot above-ground point cloud
  output$tree_plot_v1 <- renderPlot({ # opened in a pop-up window
    
    id <- showNotification("Creating plot in pop-up window...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if(req(input$submit_classes_v1)) {
      isolate(plot(tree_v1(), size = 3, bg = "white"))
    }
  }) 
  
  ## Save point cloud data (LAZ files), table with number of points per class and table of CSF parameters 
  observeEvent(input$save_classified_data_v1, {
    
    id <- showNotification("Saving data...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    writeLAS(raw(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_ground_classification.laz"))
    writeLAS(gnd_v1(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_groundonly.laz"))
    writeLAS(tree_v1(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_aboveground.laz"))
    write.csv(PointNo_table_v1(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_classification_number_of_points_per_class.csv"),
              row.names = F)
  })
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel3_2, {
    updateTabsetPanel(session, "data_processing", selected = "tabPanel3_2")
  })
  
  ## conditionalPanel - Upload classified data - "v2" ####
  
  ## Get path to already classified data
  
  shinyFileChoose(input, 'input_classified', roots = getVolumes()(), filetypes = c('','laz', 'las'))
  file_selected_classified <- eventReactive(input$input_classified, {
    req(input$input_classified)
    parseFilePaths(getVolumes()(), input$input_classified)
  })  
  output$input_classified_path <- renderText(as.character(file_selected_classified()$datapath))
  
  ## Load already classified data
  raw_classified <- reactive({
    
    id <- showNotification("Reading data...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    readLAS(as.character(file_selected_classified()$datapath)) # point cloud with ground classification in LAS format
  })
  
  ## Check if selected layer exists
  observeEvent(input$check_layer_v2, {
    test <- input$layer_class_v2
    if(!is.null(isolate({raw_classified()$Classification}))) { 
      output$output_check_layer_v2 <- renderText({"Layer exists."})
    } else if(is.null(isolate({raw_classified()$Classification}))) {
      output$output_check_layer_v2 <- renderText({"Layer doesn't exist."})
    }
  })
  
  ## Create table with number of points per class
  PointNo_table_v2 <- eventReactive(input$create_table_pointNo_v2, {
    
    id <- showNotification("Creating table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    PointNo_table_v2 <- data.frame(matrix(nrow = 2, ncol=2))
    colnames(PointNo_table_v2) <- c("Class", "Number of points")
    PointNo_table_v2[1,2] <- table(raw_classified()@data$Classification)[[2]] # ground points
    PointNo_table_v2[1,1] <- "Ground"
    PointNo_table_v2[2,2] <- table(raw_classified()@data$Classification)[[1]] # aboveground points
    PointNo_table_v2[2,1] <- "Above ground"
    PointNo_table_v2
  }) 
  
  ## Render table
  output$pointData_v2 <- renderTable({
    PointNo_table_v2()
  })
  
  ### Create point clouds of ground and above-ground points
  
  ## Create point cloud of ground points
  gnd_v2 <- reactive({
    
    id <- showNotification("Creating point cloud of ground points...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
      filter_poi(raw_classified(), Classification==input$ground_class_v2)
  })
  
  ## Create point cloud of above-ground points
  tree_v2 <- reactive({
    if (input$aboveground_class_v2 == "Every class except for the ground class") {
      
      id <- showNotification("Creating point cloud of above-ground points...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      filter_poi(raw_classified(), Classification!=input$ground_class_v2)
      
    } else if (input$aboveground_class_v2 == "Select class")  {
      
      id <- showNotification("Creating point cloud of above-ground points...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      filter_poi(raw_classified(), Classification==input$canopy_class_v2)
    }
  })
  
  ## Plot ground point cloud
  output$ground_plot_v2 <- renderPlot({ # opened in a pop-up window
    
    id <- showNotification("Creating plot in pop-up window...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if(req(input$submit_classes_v2)) { 
      isolate(plot(gnd_v2(), size = 3, bg = "white"))
    }
  }) 
  
  ## Plot above-ground point cloud
  output$tree_plot_v2 <- renderPlot({ # opened in a pop-up window
    
    id <- showNotification("Creating plot in pop-up window...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if(req(input$submit_classes_v2)) {
      isolate(plot(tree_v2(), size = 3, bg = "white"))
    }
  }) 
  
  ## Save point cloud data (LAZ files), table with number of points per class and table of CSF parameters
  observeEvent(input$save_preclassified_data_v2, {
    
    id <- showNotification("Saving data...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    writeLAS(raw_classified(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_ground_classification.laz"))
    writeLAS(gnd_v2(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_groundonly.laz"))
    writeLAS(tree_v2(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_aboveground.laz"))
    write.csv(PointNo_table_v2(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_classification_number_of_points_per_class.csv"),
              row.names = F)
  })
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel3_2, {
    updateTabsetPanel(session, "data_processing", selected = "tabPanel3_2")
  })
  
  ## conditionalPanel - Classify data - "v3" ####
  
  ### Ground classification
  
  ## Classify point cloud
  raw_cl_csf <- eventReactive(input$run_classification, {
    
    id <- showNotification("Classifiying data...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    classify_ground(raw(), algorithm = csf(sloop_smooth = FALSE, class_threshold = input$classThreshold, cloth_resolution = input$clothResolution, rigidness = input$rigidness, iterations = 500L, time_step = 0.65))
  })
  
  ## Create point cloud of ground points 
  gnd_v3 <- reactive({
    filter_poi(raw_cl_csf(), Classification==2)
  })
  
  ## Create point cloud of above-ground points 
  tree_v3 <- reactive({
    filter_poi(raw_cl_csf(), Classification!=2) # Classification==1 | Classification==0 for unassigned and never classified
  })
  
  ## Plot ground points 
  output$ground_plot_v3 <- renderPlot({ # opened in a pop-up window
    if(req(input$submit_classes_v3)) {
      
      id <- showNotification("Creating plot in pop-up window...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      isolate(plot(gnd_v3(), size = 3, bg = "white"))
    }
  }) 
  
  ## Plot above-ground points
  output$tree_plot_v3 <- renderPlot({ # opened in a pop-up window
    if(req(input$submit_classes_v3)) {
      
      id <- showNotification("Creating plot in pop-up window...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      isolate(plot(tree_v3(), size = 3, bg = "white"))
    }
  }) 
  
  ## Create table with number of points per class
  PointNo_table_v3 <- reactive({
    PointNo_table_v3 <- data.frame(matrix(nrow = 2, ncol=2))
    colnames(PointNo_table_v3) <- c("Class", "Number of points")
    PointNo_table_v3[1,2] <- table(raw_cl_csf()@data$Classification)[[2]] # ground points
    PointNo_table_v3[1,1] <- "Ground"
    PointNo_table_v3[2,2] <- table(raw_cl_csf()@data$Classification)[[1]] # canopy points
    PointNo_table_v3[2,1] <- "Above ground"
    PointNo_table_v3
  })
  
  ## Render table
  output$pointData_v3 <- renderTable({
    PointNo_table_v3()
  })
  
  ## Create table of CSF parameters
  CSF_parameters <- reactive({
    CSF_parameters <- data.frame(matrix(nrow=1, ncol=3))
    colnames(CSF_parameters) <- c("Classification threshold", "Cloth resolution", "Rigidness")
    CSF_parameters[1,1] <- input$classThreshold
    CSF_parameters[1,2] <- input$clothResolution
    CSF_parameters[1,3] <- input$rigidness
    CSF_parameters
  })
  
  ## Save point cloud data (LAZ files), table with number of points per class and table of CSF parameters
  observeEvent(input$save_classified_data_v3, {
    
    id <- showNotification("Saving data...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    writeLAS(raw_cl_csf(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_ground_classification.laz"))
    writeLAS(gnd_v3(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_groundonly.laz"))
    writeLAS(tree_v3(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_aboveground.laz"))
    write.csv(PointNo_table_v3(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_classification_number_of_points_per_class.csv"),
              row.names = F)
    write.csv(CSF_parameters(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_CSF_parameters.csv"),
              row.names = F)
  })
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel3_2, {
    updateTabsetPanel(session, "data_processing", selected = "tabPanel3_2")
  })
  
  ## DTM, DSM, CHM slope, aspect ####
  
  ## Create DTM
  
  ## Generate DTM
  dtm_tin <- eventReactive(input$generateDTM, {
    
    id <- showNotification("Generating DTM...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if (!file.exists(paste0(output_directory(), "/", input$plotName , "/", input$plotName,"_DTM.tif"))) {
      if(input$classification_selection == 'v1') {
        rasterize_terrain(raw(), res = input$resolution_DEM, algorithm = tin(max_edge = 8)) 
      } else if (input$classification_selection == 'v2') {
        rasterize_terrain(raw_classified(), res = input$resolution_DEM, algorithm = tin(max_edge = 8)) 
      } else if (input$classification_selection == 'v3') {
        rasterize_terrain(raw_cl_csf(), res = input$resolution_DEM, algorithm = tin(max_edge = 8)) 
      }
    } else {
      rast(paste0(output_directory(), "/", input$plotName,"/", input$plotName,"_DTM.tif"))
    }
  })
  
  ## Plot DTM
  output$DTM <- renderPlot({
    if(!is.null(dtm_tin())) {
      
      id <- showNotification("Creating plot...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      isolate(plot(dtm_tin(), col = height.colors(25)))
    }
  })
  
  ## Too big file: cut point cloud into two parts (10% overlap in the middle), do the rasterization on the separate files, and merge the resulting DTMs
  dtm_tin_half1 <- eventReactive(input$generateDTM_v2,{
    
    id <- showNotification("Generating DTM 1...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if(input$classification_selection == 'v1') {
      raw_1 <- clip_rectangle(raw(), min(raw()$X), min(raw()$Y), min(raw()$X)+(max(raw()$X)-min(raw()$X))/2+(max(raw()$X)-min(raw()$X))/5, max(raw()$Y))
      rasterize_terrain(raw_1, res = input$resolution_DEM, algorithm = tin(max_edge = 8)) 
    } else if (input$classification_selection == 'v2') {
      raw_1 <- clip_rectangle(raw_classified(), min(raw()$X), min(raw()$Y), min(raw()$X)+(max(raw()$X)-min(raw()$X))/2+(max(raw()$X)-min(raw()$X))/5, max(raw()$Y))
      rasterize_terrain(raw_1, res = input$resolution_DEM, algorithm = tin(max_edge = 8)) 
    } else if (input$classification_selection == 'v3') {
      raw_1 <- clip_rectangle(raw_cl_csf(), min(raw_cl_csf()$X), min(raw_cl_csf()$Y), min(raw_cl_csf()$X)+(max(raw_cl_csf()$X)-min(raw_cl_csf()$X))/2+(max(raw_cl_csf()$X)-min(raw_cl_csf()$X))/5, max(raw_cl_csf()$Y))
      rasterize_terrain(raw_1, res = input$resolution_DEM, algorithm = tin(max_edge = 8)) 
    }
  })
  
  dtm_tin_half2 <- eventReactive(input$generateDTM_v2,{
    
    id <- showNotification("Generating DTM 2...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if(input$classification_selection == 'v1') {
      raw_2 <- clip_rectangle(raw(), min(raw()$X)+(max(raw()$X)-min(raw()$X))/2-(max(raw()$X)-min(raw()$X))/5, min(raw()$Y), max(raw()$X), max(raw()$Y))
      rasterize_terrain(raw_2, res = input$resolution_DEM, algorithm = tin(max_edge = 8)) 
    } else if (input$classification_selection == 'v2') {
      raw_2 <- clip_rectangle(raw_classified(), min(raw()$X)+(max(raw()$X)-min(raw()$X))/2-(max(raw()$X)-min(raw()$X))/5, min(raw()$Y), max(raw()$X), max(raw()$Y))
      rasterize_terrain(raw_2, res = input$resolution_DEM, algorithm = tin(max_edge = 8)) 
    } else if (input$classification_selection == 'v3') {
      raw_2 <- clip_rectangle(raw_cl_csf(), min(raw_cl_csf()$X)+(max(raw_cl_csf()$X)-min(raw_cl_csf()$X))/2-(max(raw_cl_csf()$X)-min(raw_cl_csf()$X))/5, min(raw_cl_csf()$Y), max(raw_cl_csf()$X), max(raw_cl_csf()$Y))
       rasterize_terrain(raw_2, res = input$resolution_DEM, algorithm = tin(max_edge = 8)) 
    }
  })
  
  merged_dtm <- reactive({
    if(!is.null(dtm_tin_half1()) & !is.null(dtm_tin_half2())) {
     mosaic(dtm_tin_half1(), dtm_tin_half2())
    }
    })
  
  
  ## Plot DTM
  output$DTM_v2 <- renderPlot({
    if(!is.null(merged_dtm())) {
      
      id <- showNotification("Creating plot...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      isolate(plot(merged_dtm(), col = height.colors(25)))
    }
  })
  
  observeEvent(input$jumpToTabPanel3_3, {
    updateTabsetPanel(session, "data_processing", selected = "tabPanel3_3")
  })
  
  ## Generate DSM
  dsm_tin <- eventReactive(input$generateDSM, {
    
    id <- showNotification("Generating DSM...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if (!file.exists(paste0(output_directory(), "/", input$plotName , "/", input$plotName,"_DSM.tif"))) {
      if(input$classification_selection == 'v1') {
          rasterize_canopy(raw(), res = input$resolution_DEM, algorithm = dsmtin(max_edge = 8))
        } else if (input$classification_selection == 'v2') {
          rasterize_canopy(raw_classified(), res = input$resolution_DEM, algorithm = dsmtin(max_edge = 8)) 
        } else if (input$classification_selection == 'v3') {
          rasterize_canopy(raw_cl_csf(), res = input$resolution_DEM, algorithm = dsmtin(max_edge = 8)) 
        }
    } else {
      rast(paste0(output_directory(), "/", input$plotName,"/", input$plotName,"_DSM.tif"))
    }
  }) 
  
  ## Plot DSM
  output$DSM <- renderPlot({
    if(!is.null(dsm_tin())) {
      
      id <- showNotification("Creating plot...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      isolate(plot(dsm_tin(), col = height.colors(25)))
    }
  })
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel3_4, {
    updateTabsetPanel(session, "data_processing", selected = "tabPanel3_4")
  })
  
  ## If the DTM is merged, DSM and DTM should be cropped into the same size!
  dsm_cropped <- reactive({
    if (input$dtm_version2 == 1) {
    crop(dsm_tin(), as.polygons(merged_dtm() > -Inf), mask= T)
    }
    })
  
  ## Generate CHM
  chm_tin <-eventReactive(input$generateCHM, {
    
    id <- showNotification("Generating CHM...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if (input$dtm_version2 == 1) {
       dsm_cropped() -  merged_dtm() # crop dtm to the size of dsm
    } else {
       dsm_tin() - dtm_tin()
    }
  })
  
  ## Plot CHM
  output$CHM <- renderPlot({
    if(!is.null(chm_tin())) {
      
      id <- showNotification("Creating plot...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      plot(chm_tin(), col = height.colors(25))
    }
  })
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel3_5, {
    updateTabsetPanel(session, "data_processing", selected = "tabPanel3_5")
  })
  
  ## Create slope of DTM
  slope <- eventReactive(input$generateSlope, {
    
    id <- showNotification("Generating Slope...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if (input$dtm_version2 == 1) {
      terra::terrain(merged_dtm(),'slope', unit = 'degrees')
    } else {
      terra::terrain(dtm_tin(),'slope', unit = 'degrees')
    }
    })
  
  ## Plot slope
  output$slope_plot <- renderPlot({
    if (!is.null(slope())) {
      
      id <- showNotification("Creating plot...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      plot(slope())
    }
  })
  
  ## Generate aspect of DTM
  aspect <- eventReactive(input$generateAspect, {
    
    id <- showNotification("Generating Aspect...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if (input$dtm_version2 == 1) {
      terra::terrain(merged_dtm(), 'aspect', unit = 'degrees')
    } else {
      terra::terrain(dtm_tin(), 'aspect', unit = 'degrees')
    }
  })
  
  ## Plot aspect
  output$aspect_plot <- renderPlot({
    if (!is.null(aspect())) {
      
      id <- showNotification("Creating plot...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      plot(aspect())
    }
  })
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel3_6, {
    updateTabsetPanel(session, "data_processing", selected = "tabPanel3_6")
  })
  
  ## Create table of DTM/DSM/CHM resolution
  DEM_resolution <- reactive({
    DEM_resolution <- data.frame(matrix(nrow=1, ncol=1))
    colnames(DEM_resolution) <- c("DTM/DSM/CHM resolution (m)")
    DEM_resolution[1,1] <- input$resolution_DEM
    DEM_resolution
  })
  
  ## Save raster files (DTM, DSM, CHM, slope, aspect)
  observeEvent(input$save_raster_files, {
    
    id <- showNotification("Saving data...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    write.csv(DEM_resolution(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_DEM_resolution.csv"),
              row.names = F)
    if (input$dtm_version2 == 1) {
      terra::writeRaster(merged_dtm(), filename = paste0(output_directory(), "/", input$plotName,"/",input$plotName, "_DTM.tif"), overwrite = T)
      terra::writeRaster(dsm_cropped(), filename = paste0(output_directory(), "/", input$plotName,"/",input$plotName, "_DSM.tif"), overwrite = T)
    } else {
      if (!file.exists(paste0(output_directory(), "/", input$plotName , "/", input$plotName,"_DTM.tif"))) {
        terra::writeRaster(dtm_tin(), filename = paste0(output_directory(), "/", input$plotName,"/",input$plotName, "_DTM.tif"), overwrite = T)
      }
      if (!file.exists(paste0(output_directory(), "/", input$plotName , "/", input$plotName,"_DSM.tif"))) {
        terra::writeRaster(dsm_tin(), filename = paste0(output_directory(), "/", input$plotName,"/",input$plotName, "_DSM.tif"), overwrite = T)
      }
    }
    terra::writeRaster(chm_tin(), filename = paste0(output_directory(), "/", input$plotName,"/",input$plotName, "_CHM.tif"), overwrite = T)
    terra::writeRaster(slope(), filename = paste0(output_directory(), "/", input$plotName,"/",input$plotName, "_slope.tif"), overwrite = T)
    terra::writeRaster(aspect(), filename = paste0(output_directory(), "/", input$plotName,"/",input$plotName, "_aspect.tif"), overwrite = T)
  })
  
  ## Save table with number of points per classes
  PointNo_table2 <- reactive({
    
    id <- showNotification("Loading table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    read.csv(paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_classification_number_of_points_per_class.csv"),
             row.names = NULL, header = T)
  })
  
  ## Donwload report of elevation models as HTML
  output$download_report2 <- downloadHandler(
    filename = "elevation_models.html",
    content = function(file) {
      
      id <- showNotification("Downloading report...", duration = NULL, closeButton = FALSE) # create notification for user: https://mastering-shiny.org/action-feedback.html#transient-notification
      on.exit(removeNotification(id), add = TRUE)
      
      res <- rmarkdown::render(
        "elevation_models.Rmd",
        params = list(
          output_directory = output_directory(),
          plotName = input$plotName,
          classification_selection = input$classification_selection,
          CSF_parameters = CSF_parameters(),
          PointNo_table2 = PointNo_table2(),
          DEM_resolution = input$resolution_DEM,
          dtm_tin =  if (input$dtm_version2 == 1) {
            merged_dtm()
          } else {
            dtm_tin()
          },
          dsm_tin =  if (input$dtm_version2 == 1) {
            dsm_cropped()
          } else {
            dsm_tin()
          },
          chm_tin = chm_tin(),
          slope = slope(),
          aspect = aspect()
        )
      )
      file.rename(res, file)
    }
  )
  
  ## Download report of elevation models as PDF
  output$download_report2_pdf <- downloadHandler(
    filename = "elevation_models.pdf",
    content = function(file) {
      
      id <- showNotification("Downloading report...", duration = NULL, closeButton = FALSE) # create notification for user: https://mastering-shiny.org/action-feedback.html#transient-notification
      on.exit(removeNotification(id), add = TRUE)
      
      res <- rmarkdown::render(
        "elevation_models_forPDF.Rmd",
        params = list(
          output_directory = output_directory(),
          plotName = input$plotName,
          classification_selection = input$classification_selection,
          CSF_parameters = CSF_parameters(),
          PointNo_table2 = PointNo_table2(),
          DEM_resolution = input$resolution_DEM,
          dtm_tin =  if (input$dtm_version2 == 1) {
            merged_dtm()
          } else {
            dtm_tin()
          },
          dsm_tin =  if (input$dtm_version2 == 1) {
            dsm_cropped()
          } else {
            dsm_tin()
          },
          chm_tin = chm_tin(),
          slope = slope(),
          aspect = aspect()
        )
      )
      file.rename(res, file)
    }
  )
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel4, {
    updateTabsetPanel(session, "PC2RCHIVE", selected = "tabPanel4")
    updateTabsetPanel(session, "indiv_tree_segm", selected = "tabPanel4_1")
  })
  
  ######### tabPanel4 - tree detection ####
  
  ## Reload chm
  chm_tin2 <- reactive({
    
    id <- showNotification("Loading CHM...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    rast(paste0(output_directory(), "/", input$plotName,"/", input$plotName,"_CHM.tif"))
  })
  
  ## Select linear function for treetop calculation
  lin <- reactive({
    if (input$lin_function == "other") {
      eval(parse(text=input$lin_function_manual))
    } else {
      eval(parse(text=input$lin_function))
    }
  })
  
  ## Resample raster (aggregate) by factor -> no NAs anymore
  aggr <- reactive({
    
    if(!is.null(chm_tin2())){
      
      id <- showNotification("Aggregating file...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      raster::aggregate(chm_tin2(), fact=6, fun=mean, expand=FALSE, na.rm=TRUE, filename= paste0(output_directory(), "/", input$plotName , "/", input$plotName,"_CHM_aggr.tif"), overwrite=TRUE)
      
    }
  }) 
  
  ## Smoothing aggregated CHM 
  ## LiDAR-derived Canopy Height Model (CHM) smoothing is used to eliminate spurious local maxima caused by tree branches.
  schm <- reactive({
    
    if(!is.null(aggr())){
      
      id <- showNotification("Smoothing aggregated file...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      raster::focal(aggr(), w=matrix(1/9, nc=3, nr=5), na.rm=T) 
    }
  }) 
  
  # Finds tree top positions
  ttops <- reactive({
    
    if(!is.null(lin())&(!is.null(schm()))) {
      
      id <- showNotification("Finding tree top positions...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      vwf(CHM = schm(), winFun = lin(), minHeight = input$minHeight) # minHeight sometimes: 0.6 
    }
  })
  
  ## Create polygon crown map
  crownsPoly <- reactive({
    
    if(!is.null(ttops())) {
      
      id <- showNotification("Creating polygon crown map...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      mcws(treetops = ttops(), CHM = aggr(), format = "polygons", minHeight = input$minHeight)
      
    }
  }) 
  
  ## Create plot of tree crowns and tops
  output$crownPoly_treeTops <- renderPlot({
    
    if(req(input$submit_treePoly_map)) {
      
      id <- showNotification("Creating plot...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      isolate(
        tm_shape(chm_tin2(), raster.warp = FALSE) +
          tm_raster() + 
          tm_grid(col = "grey", labels.show = TRUE, labels.size = 0.7) + 
          tm_shape(crownsPoly()) +
          tm_borders(lwd = 2, col = "green") +
          tm_shape(ttops()) +
          tm_dots(col = "red", size = 0.1) + 
          tm_add_legend(type = "symbol", size = 0.4, shape = 21 , col = "red", labels = "Tree tops") +
          tm_add_legend(type = "line" , col = "green", labels = "Tree crowns") +
          tm_layout(legend.outside = T)
      )
    }
  })
  
  ## Calculate crown area and crown diameter
  crownsPoly_area <- reactive({
    if(!is.null(crownsPoly())) {
      st_area(crownsPoly())
    }
  })
  crownsPoly2 <- reactive({
    if(!is.null(crownsPoly_area())) {
      crownsPoly2 <- crownsPoly()
      crownsPoly2$crownArea <- crownsPoly_area()
      crownsPoly2$crownDiameter <- sqrt(crownsPoly2$crownArea/ pi) * 2
      crownsPoly2
    }
  })
  
  ## Extract un-smoothed CHM values in polygons
  chm_vals <- reactive({
    if(!is.null(crownsPoly2())) {
      raster::extract(chm_tin2(), crownsPoly2())
    }
  })
  ## Get max height for each polygon and address polygon field
  chm_vals_peaks <- reactive({
    chm_vals2 <- chm_vals() %>% drop_na() # remove NA's
    chm_vals2 %>% group_by(ID) %>% summarise(max_Z = max(Z))
  })
  crownsPoly3 <- reactive({
    if(!is.null(chm_vals_peaks())) {
      crownsPoly3 <- crownsPoly2()
      crownsPoly3$orgHeight <- chm_vals_peaks()$max_Z
      crownsPoly3
    }
  })
  
  
  ## Delete ttops without crownPoly
  ttops_filt <- reactive({
    ttops() %>% filter(ttops()$treeID %in% crownsPoly3()$treeID)
  })
  
  ## Plot trees
  treePoly_map_final <- eventReactive(input$submit_treePoly_map_2, {
      tm_shape(chm_tin2(), raster.warp = FALSE) +
        tm_raster() + 
        tm_grid(col = "grey", labels.show = TRUE, labels.size = 0.7) +  #labels.rot = c(90,0)
        tm_shape(crownsPoly3()) +
        tm_borders(lwd = 2, col = "green") +
        tm_shape(ttops_filt()) +
        tm_dots(col = "red", size = 0.1) + 
        tm_add_legend(type = "symbol", size = 0.4, shape = 21 , col = "red", labels = "Tree tops") +
        tm_add_legend(type = "line" , col = "green", labels = "Tree crowns") +
        tm_layout(legend.outside = T)
  })
  
  ## Create plot of tree height and tops - filter out "crownless" treetops
  output$crownPoly_treeTops_filt <- renderPlot({
      
      id <- showNotification("Creating plot...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      treePoly_map_final()
      
  })
  
  ## Create table of parameters used for treetop detection
  tree_segm_parameters <- reactive({
    tree_segm_parameters <- data.frame(matrix(nrow=1, ncol=2))
    colnames(tree_segm_parameters) <- c("Linear function for LMF", "Min tree height parameter")
    tree_segm_parameters[1,1] <- ifelse(input$lin_function == "other", input$lin_function_manual, input$lin_function)
    tree_segm_parameters[1,2] <- input$minHeight
    tree_segm_parameters
  })
  
  ## Export polygons as shape-file and save table of used parameters
  observeEvent(input$save_tree_shapefiles, {
    
    id <- showNotification("Saving data...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if (!dir.exists(paste0(output_directory(), "/", input$plotName , "/", input$plotName, "_crownsPoly"))) {
      dir.create(paste0(output_directory(), "/", input$plotName , "/", input$plotName, "_crownsPoly"))}
    st_write(ttops_filt(), paste0(output_directory(), "/", input$plotName , "/", input$plotName, "_crownsPoly/",input$plotName ,"_ttops.shp"),driver="ESRI Shapefile", delete_dsn = T) 
    st_write(crownsPoly3(), paste0(output_directory(), "/", input$plotName , "/", input$plotName, "_crownsPoly/",input$plotName ,"_crownsPoly.shp"), driver="ESRI Shapefile", delete_dsn = T)
    write.csv(tree_segm_parameters(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_tree_segmentation_parameters.csv"),
              row.names = F)
  })
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel4_2, {
    updateTabsetPanel(session, "indiv_tree_segm", selected = "tabPanel4_2")
  })
  
  ## Generate point cloud with trees only
  aboveGround_cl <- reactive({
    readLAS(paste0(output_directory(), "/",input$plotName,"/", input$plotName,"_aboveground.laz"))
  })
  
  ## Reload crownspoly shape file
  crownsPoly_reread <- reactive({
    st_read(dsn = paste0(output_directory(), "/",input$plotName,"/", input$plotName,"_crownsPoly"), layer = paste0(input$plotName, "_crownsPoly"))
  })
  
  ## Add treeIDs to above-ground point cloud 
  aboveGround_cl_withID <- reactive({
    aboveGround_cl_withID <- merge_spatial(aboveGround_cl(), crownsPoly_reread(), "treeID")
    add_lasattribute(aboveGround_cl_withID, name="treeID", desc="ID of a tree") # to fix a bug: https://gis.stackexchange.com/questions/318845/lidr-rlas-writelas-changes-values-from-classification-attribute
  })

  ## Plot point cloud of trees
  output$tree_plot_v4 <- renderPlot({ # opened in a pop-up window
    if(input$plot_treesonly_laz>0) {
      
      id <- showNotification("Creating plot in pop-up window...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      isolate(plot(treesonly_withID(), size = 3, bg = "white"))
    }
  }) 
  
  ## Table with number of tree points
  PointNo_table_v4 <- reactive({
    PointNo_table_v4 <- data.frame(matrix(nrow = 1, ncol=2))
    colnames(PointNo_table_v4) <- c("Class", "Number of points")
    PointNo_table_v4[1,2] <- table(treesonly_withID()@data$Classification)[[1]] # tree points
    PointNo_table_v4[1,1] <- "Tree"
    PointNo_table_v4
  })
  
  ## Show table
  output$pointData_v4 <- renderTable({
    PointNo_table_v4()
  })
  
  ## Create point cloud from tree points
  treesonly_withID <- eventReactive(input$generate_treesonly_laz , {
    
    id <- showNotification("Generating point cloud...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    aboveGround_cl_withID()[!is.na(aboveGround_cl_withID()$treeID)]
  })
  
  ## Load point cloud with ground classification if file is not loaded into the program (for adding tree ID-s)
  ground_cl <- reactive({
    
    id <- showNotification("Reloading point cloud...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    readLAS(paste0(output_directory(), "/",input$plotName,"/", input$plotName,"_ground_classification.laz"))
  })
  
  ## Create point cloud with tree IDs
  ground_cl_withID <- reactive({
    
    id <- showNotification("Adding tree ID-s...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if (input$reload_PC_cl == 1) {
      ground_cl_withID <- merge_spatial(ground_cl(), crownsPoly_reread(), "treeID")
      ground_cl_withID <- add_lasattribute(ground_cl_withID, name="treeID", desc="ID of a tree")
      ground_cl_withID$treeID[ground_cl_withID$Classification==2] <- NA
      ground_cl_withID
    } else { 
      if (input$classification_selection == 'v1') {
        ground_cl_withID <- merge_spatial(raw(), crownsPoly_reread(), "treeID")
        ground_cl_withID <- add_lasattribute(ground_cl_withID, name="treeID", desc="ID of a tree")
        ground_cl_withID$treeID[ground_cl_withID$Classification==2] <- NA
        ground_cl_withID 
      } else if (input$classification_selection == 'v2') {
        ground_cl_withID <- merge_spatial(raw_classified(), crownsPoly_reread(), "treeID")
        ground_cl_withID <- add_lasattribute(ground_cl_withID, name="treeID", desc="ID of a tree")
        ground_cl_withID$treeID[ground_cl_withID$Classification==2] <- NA
        ground_cl_withID 
      } else if (input$classification_selection == 'v3') {
        ground_cl_withID <- merge_spatial(raw_cl_csf(), crownsPoly_reread(), "treeID")
        ground_cl_withID <- add_lasattribute(ground_cl_withID, name="treeID", desc="ID of a tree")
        ground_cl_withID$treeID[ground_cl_withID$Classification==2] <- NA
        ground_cl_withID
      }
    }
  })
  
  ## Save point cloud files (save 'treesonly' and rewrite above-ground PC), save table of tree points
  observeEvent(input$save_treesOnly_laz_file, {
    
    id <- showNotification("Saving data...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    ## overwrite original _aboveground.laz file with new version of it: treeIDs are now included!
    writeLAS(aboveGround_cl_withID(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_aboveground.laz"))
    writeLAS(treesonly_withID(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_treesonly.laz"))
    writeLAS(ground_cl_withID(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_ground_classification.laz"))
    write.csv(PointNo_table_v4(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_classification_number_of_points_per_class2.csv"),
              row.names = F)
  })
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel4_3, {
    updateTabsetPanel(session, "indiv_tree_segm", selected = "tabPanel4_3")
  })
  
  ## Create histogram and density plot - tree height
  histogram <- reactive({
    ggplot(crownsPoly3(), aes(x=orgHeight)) +  #aes(x=orgHeight[orgHeight>0.4])
      geom_histogram(color="black", fill="white") +
      xlab(paste0("Height of trees (m)")) + #- with trees greater than ", input$minHeight, " m" #input$minHeight_forStatistics
      ylab("Number of trees") +
      ggtitle("Histogram") +
      theme(plot.title = element_text(hjust = 0.5))
  })
  density <- reactive({
    ggplot(crownsPoly3(), aes(x=orgHeight)) + 
      geom_histogram(aes(y=..density..), color="black", fill="white") + #aes(x=orgHeight[orgHeight>0.4])
      xlab(paste0("Height of trees (m)")) + #  - with trees greater than ", input$minHeight, " m #input$minHeight_forStatistics
      ylab("Density") +
      geom_density(alpha=.2, fill="#FF6666") +
      ggtitle("Density plot") +
      theme(plot.title = element_text(hjust = 0.5))
  })
  
  ## Plot histogram and density plot
  output$hist_treeH <- renderPlot({
    if(input$create_hist>0) {
      
      id <- showNotification("Creating plots...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      
      isolate(
        ggarrange(histogram(), density(), ncol=2, nrow = 1)
      )
    }
  })
  
  ## Create table of tree stand statistics
  sum_table2 <- eventReactive(input$tree_statistics, {
    
    id <- showNotification("Creating table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    height_stat <- crownsPoly3() %>% summarise(mean(orgHeight), min(orgHeight), max(orgHeight))
    crownDiameter_stat <- crownsPoly3() %>% summarise(mean(crownDiameter))
    sum_table <- data.frame(matrix(nrow=1, ncol=5))
    colnames(sum_table) <- c("number of trees detected","meanHeight (m)", "minHeight (m)", "maxHeight (m)", "meanCrownDiameter (m)")
    sum_table[1] <- length(unique(treesonly_withID()$treeID))
    sum_table[2] <- round(height_stat$`mean(orgHeight)`, digits = 3)
    sum_table[3] <- round(height_stat$`min(orgHeight)`, digits = 3)
    sum_table[4] <- round(height_stat$`max(orgHeight)`, digits = 3)
    sum_table[5] <- round(drop_units(crownDiameter_stat$`mean(crownDiameter)`), digits = 3)
    sum_table
  })
  
  ## Visualize table
  output$tree_statistics_table <- renderTable({
    if(!is.null(sum_table2())){
      sum_table2()
    }
  })
  
  ## Save table of tree statistics
  observeEvent(input$save_tree_segm_csvs, {
    
    id <- showNotification("Saving data...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    write.csv(sum_table2(), paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_tree_statistics_table.csv"),
              row.names = F)
  })
  
  ## Download report of tree segmentation as HTML
  output$download_report3 <- downloadHandler(
    filename = "tree_segmentation.html",
    content = function(file) {
      
      id <- showNotification("Downloading report...", duration = NULL, closeButton = FALSE) # create notification for user: https://mastering-shiny.org/action-feedback.html#transient-notification
      on.exit(removeNotification(id), add = TRUE)
      
      res <- rmarkdown::render(
        "tree_segmentation.Rmd",
        params = list(output_directory = output_directory(),
                      plotName = input$plotName,
                      tree_segm_parameters = tree_segm_parameters(), 
                      treePoly_map_final = treePoly_map_final(),
                      histogram = histogram(),
                      density = density(),
                      PointNo_table_v4 = PointNo_table_v4(),
                      sum_table2 = sum_table2()
                      )
      )
      file.rename(res, file)
    }
  )
  
  ## Download report of tree segmentation as PDF
  output$download_report3_pdf <- downloadHandler(
    filename = "tree_segmentation.pdf",
    content = function(file) {
      
      id <- showNotification("Downloading report...", duration = NULL, closeButton = FALSE) # create notification for user: https://mastering-shiny.org/action-feedback.html#transient-notification
      on.exit(removeNotification(id), add = TRUE)
      
      res <- rmarkdown::render(
        "tree_segmentation_forPDF.Rmd",
        params = list(output_directory = output_directory(),
                      plotName = input$plotName,
                      tree_segm_parameters = tree_segm_parameters(), 
                      treePoly_map_final = treePoly_map_final(),
                      histogram = histogram(),
                      density = density(),
                      PointNo_table_v4 = PointNo_table_v4(),
                      sum_table2 = sum_table2()
        )
      )
      file.rename(res, file)
    }
  )
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel5, {
    updateTabsetPanel(session, "PC2RCHIVE", selected = "tabPanel5")
    updateTabsetPanel(session, "maps_and_report", selected = "tabPanel5_1")
  })
  
  ######### tabPanel5 - map ####
  
  ### Calculate footprint
  
  ## Load aggregated CHM
  aggr2 <-reactive({
    
    id <- showNotification("Loading aggr. CHM...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    rast(paste0(output_directory(), "/", input$plotName,"/", input$plotName,"_CHM_aggr.tif"))
  })
  
  ## Create footprint - sf, in utm
  boundary_sf_utm <- reactive({ # sf
    
    id <- showNotification("Creating footprint boundary in UTM...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    boundary_SpVect <- as.polygons(aggr2() > -Inf) ## boundary of raster: SpatVector
    st_as_sf(boundary_SpVect)
  })
  
  ## Create footprint - sf, in longlat
  boundary_sf_longlat <- eventReactive(input$create_footprint, {
    
    id <- showNotification("Creating footprint boundary in latlong...", duration = NULL, closeButton = FALSE) 
    on.exit(removeNotification(id), add = TRUE)
    
    boundary_sf_longlat_full <- st_transform(boundary_sf_utm(), crs=4326) ## sf, as latlong
    boundary_sf_longlat_full$geometry
  }) 
  
  ## Plot footprint (longlat)
  output$plot_boundary <- renderPlot({
    if(!is.null(boundary_sf_longlat())) {
      plot(boundary_sf_longlat())
    }
  })
  
  ## Save footprint polygon
  observeEvent(input$save_footprint, {
    
    id <- showNotification("Saving file...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if (!dir.exists(paste0(output_directory(), "/", input$plotName , "/", input$plotName, "_footprint"))) {
      dir.create(paste0(output_directory(), "/", input$plotName , "/", input$plotName, "_footprint"))}
    st_write(boundary_sf_utm(), paste0(output_directory(), "/", input$plotName , "/", input$plotName ,"_footprint/",input$plotName ,"_footprint_utm.shp"), delete_layer = TRUE)
    st_write(boundary_sf_longlat(), paste0(output_directory(), "/", input$plotName , "/", input$plotName ,"_footprint/",input$plotName ,"_footprint_LongLat.shp"), delete_layer = TRUE)
  })
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel5_2, {
    updateTabsetPanel(session, "maps_and_report", selected = "tabPanel5_2")
  })
  
  ### Create UTM map
  
  ## Calculating map boundary that defines the area to download
  map_boundary <- reactive({
    
    lon <- c(st_bbox(boundary_sf_longlat())[[1]]-1.5*input$extent_buffer, st_bbox(boundary_sf_longlat())[[3]]+1.5*input$extent_buffer)
    lat <- c(st_bbox(boundary_sf_longlat())[[2]]-input$extent_buffer,st_bbox(boundary_sf_longlat())[[4]]+input$extent_buffer)
    
    df_coord_for_map_boundary <- data.frame(lon, lat)
    
    df_coord_for_map_boundary %>% 
      st_as_sf(coords = c("lon", "lat"), 
               crs = 4326) %>% 
      st_bbox() %>% 
      st_as_sfc()
  })
  
  ## EPSG code of the respective UTM zone
  crs_plot <- reactive({
    32600 + (floor((st_bbox(boundary_sf_longlat())[[1]] + 180)/6) + 1)
  }) 
  
  ## Getting bounding box coordinates of footprint
  bbox_coord2 <- reactive({
    
    x <- c(st_bbox(boundary_sf_utm())[[1]], st_bbox(boundary_sf_utm())[[3]])
    y <- c(st_bbox(boundary_sf_utm())[[2]],st_bbox(boundary_sf_utm())[[4]])
    longlat <- c(paste0(round(st_bbox(boundary_sf_longlat())[[1]], 5), " / ", round(st_bbox(boundary_sf_longlat())[[2]],5)), 
                 paste0(round(st_bbox(boundary_sf_longlat())[[3]],5), " / ", round(st_bbox(boundary_sf_longlat())[[4]],5)))
    bbox_coord <- data.frame(x,y,longlat)
    
    st_as_sf(x = bbox_coord, coords = c("x", "y"), crs = crs_plot())
  })
  
  ## Load OpenStreetMap within map boundary
  osm <- reactive({ 
    
    id <- showNotification("Loading OpenStreetMap...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    read_osm(map_boundary()) 
  })
  
  ## Convert osm tile to UTM
  osm_utm <- reactive({
    st_transform(osm(), crs=crs_plot())
  }) 
  
  ## Generate UTM map
  utm.map <- reactive({
    tm_shape(osm_utm(), raster.warp = FALSE) +
      tm_rgb() + 
      tm_grid(col = "grey", labels.show = TRUE, labels.size = 1) + 
      tm_shape(boundary_sf_utm()) +
      tm_borders(lwd = 2, col = "#E84A5F") +
      tm_shape(bbox_coord2()) +
      tm_dots(col = "black", size = 0.1) + 
      tm_text("longlat", size = 1, just=c(0,1), ymod = -0.5) +
      tm_add_legend(type = "symbol", size = 0.6, shape = 21 , col = "black", labels = "Long/Lat") +
      tm_compass(position = c("RIGHT", "TOP"), size = 4) +
      tm_scale_bar(text.size = 1, position = c("RIGHT", "BOTTOM"), width = 0.3) +
      tm_layout(main.title = paste0("Footprint of point cloud - plot ", input$plotName),
                legend.outside = T, title.position = c("center", "center"))
  })
  
  ## Plot map with footprint
  output$footprint_map <- renderPlot({
    
    id <- showNotification("Creating plot...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    if(req(input$generate_map)) {
      isolate(
        tmap_mode("plot") +
          utm.map()
      ) # isolate
    } # actionbutton
  }, width = 700, height = 700
  )
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel5_3, {
    updateTabsetPanel(session, "maps_and_report", selected = "tabPanel5_3")
  })
  
  ### Create interactive maps
  
  ## Interactive map created by the leaflet package
  foundational.map <- eventReactive(input$generate_interactive_map, {
    leaflet() %>% # create a leaflet map widget
      addProviderTiles("Esri.WorldImagery", group = "Esri.WorldImagery") %>%
      addProviderTiles("OpenStreetMap", group = "OpenStreetMap") %>%
      addLayersControl(
        baseGroups = c("OpenStreetMap",
                       "Esri.WorldImagery"), position = "topleft") %>%
      addPolygons(data=boundary_sf_longlat(), color = "#E84A5F",
                  opacity = 1, fillOpacity = 0)
  })
  
  ## Render interactive map
  output$map <- renderLeaflet({
    foundational.map()
  }) 
  
  ## Set view of interactive map - with ESRI layer
  user_created_map1 <- reactive({
    foundational.map() %>%
      setView(lng = input$map_center$lng,  
              lat = input$map_center$lat, 
              zoom = input$map_zoom) %>%
      showGroup(group = "Esri.WorldImagery")
  })
  
  ## Download PNG of interactive map - with ESRI layer
  output$downloadData_esri <- downloadHandler(
    filename = function() {paste0(input$plotName, "_ESRI_footprint.png")},
    content = function(file) {
      
      id <- showNotification("Downloading image...", duration = NULL, closeButton = FALSE) 
      on.exit(removeNotification(id), add = TRUE)
      
      mapview::mapshot(x = user_created_map1(), file = file
                       , selfcontained = FALSE) 
    } # content()
  ) # downloadHandler()
  
  ## Set view of interactive map - with OSM layer
  user_created_map2 <- reactive({
    foundational.map() %>%
      setView(lng = input$map_center$lng,  
              lat = input$map_center$lat, 
              zoom = input$map_zoom) %>%
      showGroup(group = "OpenStreetMap")
  })
  
  ## Download PNG of interactive map - with OSM layer
  output$downloadData_osm <- downloadHandler(
    filename = function() {paste0(input$plotName, "_OpenStreetMap_footprint.png")}, 
    content = function(file) {
      
      id <- showNotification("Downloading image...", duration = NULL, closeButton = FALSE) 
      on.exit(removeNotification(id), add = TRUE)
      
      mapview::mapshot(x = user_created_map2(), file = file
                       , selfcontained = FALSE) 
    } # content() 
  ) # downloadHandler()
  
  ## Create final HTML report
  output$download_report4 <- downloadHandler(
    filename = function() {paste0("Report_",input$plotName, ".html")},
    content = function(file) {
      
      id <- showNotification("Downloading report...", duration = NULL, closeButton = FALSE) 
      on.exit(removeNotification(id), add = TRUE)
      
      res <- rmarkdown::render(
        "maps.Rmd",
        params = list(
          output_directory = output_directory(),
          plotName = input$plotName,
          boundary_sf_longlat = boundary_sf_longlat(),
          utm.map = utm.map(),
          user_created_map1 = user_created_map1(),
          user_created_map2 = user_created_map2()
        )
      )
      file.rename(res, file)
    }
  )
  
  ## Save maps to PDF report
  output$download_report4_pdf <- downloadHandler(
    filename = "maps.pdf",
    content = function(file) {
      
      id <- showNotification("Downloading report...", duration = NULL, closeButton = FALSE) 
      on.exit(removeNotification(id), add = TRUE)
      
      res <- rmarkdown::render(
        "maps_forPDF.Rmd",
        params = list(
          output_directory = output_directory(),
          plotName = input$plotName,
          boundary_sf_longlat = boundary_sf_longlat(),
          utm.map = utm.map(),
          user_created_map1 = user_created_map1(),
          user_created_map2 = user_created_map2()
        )
      )
      file.rename(res, file)
    }
  )

  ## Compile PDF-s into a single PDF report
  observeEvent(input$create_pdf_report, {
    
    id <- showNotification("Downloading report...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    pdf1 <- paste0(output_directory(), "/", input$plotName, "/reading_las.pdf")
    pdf2 <- paste0(output_directory(), "/", input$plotName, "/elevation_models.pdf")
    pdf3 <- paste0(output_directory(), "/", input$plotName, "/tree_segmentation.pdf")
    pdf4 <- paste0(output_directory(), "/", input$plotName, "/maps.pdf")
    pdf_combine(c(pdf1, pdf2, pdf3, pdf4) ,output  = paste0(output_directory(), "/", input$plotName, "/Report_", input$plotName,".pdf"))
  })
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel6, {
    updateTabsetPanel(session, "PC2RCHIVE", selected = "tabPanel6")
    updateTabsetPanel(session, "contributors_metadata", selected = "tabPanel6_1")
  })
  
  ######### tabPanel6 - metadata ####
  
  ### Create tables from metadata
  
  ## Load contributors table
  ## Create reactive value in which loaded metadata table will be fed
  df_contributors <- reactiveValues(loaded_csv = NULL) 
  observe({
    req(input$input_contributors)
    ## load contributors table
    loaded_contr_csv <- read.csv(input$input_contributors$datapath,
                           header = TRUE,
                           row.names = NULL)
    
    df_contributors$loaded_contr_csv <- loaded_contr_csv
  })
  
  ## Create table or add new row
  observeEvent(input$submitbutton_contributors, {
    newdat_cont <- data.frame(
      Contributor = input$contributor, 
      Function = input$contributor_function,
      Comments = input$comments
    ) 
    df_contributors$loaded_contr_csv <<- rbind(df_contributors$loaded_contr_csv, newdat_cont)
  })
  
  ## Visualization
  output$tabledata_contributors <- renderDT({
    if(!is.null(df_contributors$loaded_contr_csv)) {
      datatable(df_contributors$loaded_contr_csv, editable = "cell",
                options = list(scrollX = T, pageLength = 20)) #loaded_csv
    }
  })
  
  ## Delete last row of table
  observeEvent(input$delete_last_row_contr, {
    df_contributors$loaded_contr_csv <<- (df_contributors$loaded_contr_csv[-nrow(df_contributors$loaded_contr_csv),])
  })
  
  ## Delete selected rows (click into the table)
  observeEvent(input$deleteRow_csv_contr, {
    req(input$tabledata_contributors_rows_selected)
    df_contributors$loaded_contr_csv <<- df_contributors$loaded_contr_csv[-input$tabledata_contributors_rows_selected,]
  })
  
  ## Edit table
  observeEvent(input$tabledata_contributors_cell_edit, {
    df_contributors$loaded_contr_csv[input$tabledata_contributors_cell_edit$row,input$tabledata_contributors_cell_edit$col] <<- input$tabledata_contributors_cell_edit$value
  })
  
  ## Save contributors table
  output$download_contributors <- downloadHandler("Contributors.csv",
                                              content = function(file){
                                                write.csv(df_contributors$loaded_contr_csv, file, row.names = F)
                                              },
                                              contentType = "text/csv")
  
  ## Jump to next page
  observeEvent(input$jumpToTabPanel6_2, {
    updateTabsetPanel(session, "contributors_metadata", selected = "tabPanel6_2")
  })
  
  #### 
  
  ## Load CSV files to use their data in master table
  
  Area_table <- reactive({
    
    id <- showNotification("Loading table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    read.csv(paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_point_cloud_area_point_density.csv"),
             row.names = NULL, header = T)
  })
  
  ## Table of ground and above-ground points
  PointNo_table <- reactive({
    
    id <- showNotification("Loading table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    read.csv(paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_classification_number_of_points_per_class.csv"),
             row.names = NULL, header = T)
  })
  ## Table of CSF parameters
  CSFparameters <- reactive({
    
    id <- showNotification("Loading table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    read.csv(paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_CSF_parameters.csv"),
             row.names = NULL, header = T)
  })
  ## Table of DTM/DSM/CHM resolution
  DEM_res <- reactive({
    
    id <- showNotification("Loading table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    read.csv(paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_DEM_resolution.csv"),
             row.names = NULL, header = T)
  })
  ## Table of tree points
  PointNo_table_treesonly <- reactive({
    
    id <- showNotification("Loading table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    read.csv(paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_classification_number_of_points_per_class2.csv"),
             row.names = NULL, header = T)
  })
  ## Table of tree statistics
  tree_stat <- reactive({
    
    id <- showNotification("Loading table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    read.csv(paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_tree_statistics_table.csv"),
             row.names = NULL, header = T)
  })
  ## Table of tree segmentation parameters
  tree_segmentation_parameters <- reactive({
    
    id <- showNotification("Loading table...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    read.csv(paste0(output_directory(), "/", input$plotName ,"/",input$plotName, "_tree_segmentation_parameters.csv"),
             row.names = NULL, header = T)
  })
  
  ## Load master table
  ## Create reactive value in which loaded metadata table will be fed
  vals <- reactiveValues(loaded_csv = NULL) 
  observe({
    req(input$input_mastertable)
    ## load metadata table
    loaded_csv <- read.csv(input$input_mastertable$datapath,
                           header = TRUE,
                           row.names = NULL)
    
    vals$loaded_csv <- loaded_csv
  })
  
  ## Create new table or add new row
  observeEvent(input$addRow_csv, {
    newdat2 <- data.frame(
      "Plot" = input$plotName,
      "Event" = input$eventName,
      "Date and starting time" = input$dateOfRecording,
      "Latitude - central coord" = round(mean(st_bbox(boundary_sf_longlat())[[2]],st_bbox(boundary_sf_longlat())[[4]]), digits = 6),
      "Longitude - central coord" = round(mean(st_bbox(boundary_sf_longlat())[[1]],st_bbox(boundary_sf_longlat())[[3]]), digits = 6),
      #"Central coord in Lat/Long WGS84" = paste0(round(mean(st_bbox(boundary_sf_longlat())[[2]],st_bbox(boundary_sf_longlat())[[4]]), digits = 6), " / ", round(mean(st_bbox(boundary_sf_longlat())[[1]],st_bbox(boundary_sf_longlat())[[3]]), digits = 6)),
      "Additional info" = input$additionalInfo,
      "CRS" = paste0("UTM zone ",(floor((st_bbox(boundary_sf_longlat())[[1]] + 180)/6) + 1)),
      "Extent - xmin, ymin, xmax, ymax" = paste0(st_bbox(boundary_sf_utm())[[1]], ", ", st_bbox(boundary_sf_utm())[[2]], ", ", st_bbox(boundary_sf_utm())[[3]], ", ", st_bbox(boundary_sf_utm())[[4]]),
      "Area" = Area_table()[1,1],
      "Number of points" = Area_table()[1,2],
      "Point density" = Area_table()[1,3],
      "Coloriztaion" = input$colorization,
      "Device" = input$device, 
      "Software for preprocessing" = input$software,
      "Strip alignment" = input$strip_alignment,
      "Strip aligment error" = input$strip_aligment_error,
      "Coordinate project correction" = input$coord_proj_corr,
      "Reference frame used" = input$coord_proj_corr_reference_frame,
      "Ground classified point cloud - Filename" = paste0(input$plotName, "_ground_classification.laz"),
      "Mode of ground classification" = input$classification_mode,
      "Additional info on classification" = input$extraInfoClassification,
      "CSF parameters: Classification threshold, cloth resolution, rigidness" = if (input$classification_mode=="Data was classified using Cloth Simulation Filter") {
        paste0(CSFparameters()[1,1], ", ", CSFparameters()[1,2], ", ", CSFparameters()[1,3])
      } else {
        ""
      },
      "Number of ground points" = PointNo_table()[1,2],
      "Number of points above ground" = PointNo_table()[2,2],
      "DTM/DSM/CHM resolution (m)" = DEM_res()[1,1],
      "ITD point cloud - Filename" = paste0(input$plotName, "_treesonly.laz"),
      "Linear function for LMF" = tree_segmentation_parameters()[1,1],
      "Min tree height parameter" = tree_segmentation_parameters()[1,2],
      "Number of tree points" = PointNo_table_treesonly()[1,2],
      "Number of trees detected" = tree_stat()[1,1],
      "Mean crown diameter (m)" = tree_stat()[1,5],
      "Mean tree height (m)" = tree_stat()[1,2],
      "Max tree height (m)" = tree_stat()[1,4],
      "Min tree height (m)" = tree_stat()[1,3]
    )
    vals$loaded_csv <<- rbind(vals$loaded_csv, newdat2)
  })
  
  ## Visualization
  output$table_metadata <- renderDT({
    if(!is.null(vals$loaded_csv)) {
      datatable(vals$loaded_csv, editable = TRUE,
                options = list(scrollX = T, pageLength = 20)) #loaded_csv
    }
  })
  
  ## Delete last row
  observeEvent(input$deleteLastRow_csv, {
    vals$loaded_csv <<- (vals$loaded_csv[-nrow(vals$loaded_csv),])
  })
  
  ## Delete selected rows (click into the table)
  observeEvent(input$deleteRow_csv, {
    req(input$table_metadata_rows_selected)
    vals$loaded_csv <<- vals$loaded_csv[-input$table_metadata_rows_selected,]
  })
  
  ## Edit table
  observeEvent(input$table_metadata_cell_edit, {
    vals$loaded_csv[input$table_metadata_cell_edit$row,input$table_metadata_cell_edit$col] <<- input$table_metadata_cell_edit$value
  })
  
  ## Save metadata table
  output$download_metadata <- downloadHandler("Mastertable.csv",
                                              content = function(file){
                                                write.csv(vals$loaded_csv, file, row.names = F)
                                              },
                                              contentType = "text/csv")
  
  ## Jump to the beginning
  observeEvent(input$jumpToTheStart, {
    updateTabsetPanel(session, "PC2RCHIVE", selected = "tabPanel2")
  })
  
  ## Jump to the end
  observeEvent(input$jumpToTheEnd, {
    updateTabsetPanel(session, "PC2RCHIVE", selected = "tabPanel7")
  })
  
  ######### tabPanel7 - zipping folders ####
  
  ## List folders in parent directory
  list_to_zip <- eventReactive(input$list_folders , {
    list.dirs(path = output_directory(), full.names = F, recursive = F)
  })
  
  ## Show folders found
  output$folder_list <- renderUI({
    HTML(paste(list_to_zip(), sep = "", collapse = '<br/>'))
  })
  
  ## Zip folders
  observeEvent(input$zip_folders, {
    setwd(output_directory())
    for (i in 2:length(list_to_zip())) {
    utils::zip(paste0(list_to_zip()[i], ".zip"), list_to_zip()[i], flags = '-r')
    }
  })
  
}

#########################
## Create Shiny object ##
#########################

shinyApp(ui = ui, server = server)

