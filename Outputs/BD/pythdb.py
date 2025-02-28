######!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2020 Xavier Robert <xavier.robert@ird.fr>
# SPDX-License-Identifier: GPL-3.0-or-later


"""
##########################################################
#                                                        #  
#     Script to automatize plot of Therion databases     #
#                                                        #  
#                 By Xavier Robert                       #
#               Grenoble, february 2022                  #
#                                                        #  
##########################################################

Written by Xavier Robert, february 2022

xavier.robert@ird.fr

"""

# Do divisions with Reals, not with integers
# Must be at the beginning of the file
from __future__ import division

# Import Python modules
import numpy as np
import scipy.stats as stats
from scipy.optimize import curve_fit    # To find gaussian parameters
#from scipy.signal import find_peaks
import peakutils    # To find number of peaks
from peakutils.plot import plot as pplot
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import seaborn as sns
import sqlite3
import sys, os, copy
import datetime
from alive_progress import alive_bar              # https://github.com/rsalmei/alive-progress	

#################################################################################################
def Rose(conn, graphpath, bins = 72):
	"""
	Plot a Rose diagram of the entire database

	Args:
		conn (sqlite_db): database sqlite
		graphpath (str): path and name of the graph to save
		bins (int, optional): bins for the plot. Defaults to 72.
	"""
	
	# Extract the right data
	df = pd.read_sql_query("select * from SHOT;", conn)

	# Built the histogram
	#h, e = np.histogram(df["BEARING"] * np.pi/180., weights = df["LENGTH"], bins = bins)
	# set all the bearings between 0 and 180°
	df.loc[df["BEARING"] > 180, "BEARING"] = df.loc[df["BEARING"].index] - 180
	
	# Pour enlever les visées verticales (et donc de bearing systématiquement à 0°...)
	h, e = np.histogram(df["BEARING"] * np.pi/180., 
						weights = df["LENGTH"] * (90 - np.abs(df["GRADIENT"]))/100, 
						bins = 90)
						#kde = True,
						#kde_kws={#'clip'     : (altmin, altmax),
						#	 #'weights'  : 'LENGTH',
						#	 'bw_adjust': 0.2})
	
	#kde = stats.gaussian_kde(df["BEARING"] * np.pi/180., 
	#						 weights = df["LENGTH"] * (90 - np.abs(df["GRADIENT"]))/100,
	#						 bw_method = 0.05)
	#xx = np.linspace(0, np.pi, 1000)

	# Plot the rose diagram
	ax = plt.subplot(111, projection = "polar")
	plt.xlim(0, np.pi)
	plt.xlabel("Direction (°)")
	plt.ylabel("Longueur projetée (m)")
	ax.set_theta_zero_location("N")
	ax.set_theta_direction(-1)
	ax.bar(e[:-1], h, 
		   align = "edge", 
		   width = e[1]-e[0],
		   alpha = 0.7)
	#ax.plot(xx, kde(xx) * h.max())

	#sns.displot(data = pd.DataFrame(e[:-1]),
	#				y = h, 
	#				#weights = df["LENGTH"] * (90 - np.abs(df["GRADIENT"]))/100,
	#				#stat = 'probability', 
	#				bins = bins,
	#				#binwidth = e[1]-e[0],
	#				#binrange = (altmin, altmax), 
	#				kind = 'hist',
	#				alpha = 0.5,
	#				kde = True,
	#				kde_kws={'clip'     : (altmin, altmax),
	#						 #'weights'  : 'LENGTH',
	#						 #'bw_adjust': })
	#						 'bw_adjust': 0.2})
	
	# Save the rose diagram
	plt.savefig(graphpath + "-rose_diagram.pdf")
	# Close the graph
	plt.close(plt.figure(1))
	
	return

#################################################################################################
def Shot_lengths_histogram(conn, graphpath, bins = 72, log = None):
	"""
	Plot the histogram of the lengths of the shots for the entire database

	Args:
		conn (sqlite_db): database sqlite
		graphpath (str): path and name of the graph to save
		bins (int, optional): bins for the plot. Defaults to 72.
		log (str, optional): set it to 'log' to use a y-logscale. Defaults to None.
	"""

	# Extract the right data
	df = pd.read_sql_query("select * from SHOT;", conn)

	# plot the histogram
	plt.hist(df["LENGTH"], bins = bins)
	plt.xlabel("Longueur de visée (m)")
	plt.ylabel("Nombre")
	plt.xlim(0,50)
	
	# If log y-scale, set it
	if log:
		plt.yscale("log")
		
	# save
	plt.savefig(graphpath + "-shot_lengths_histogram.pdf")
	plt.close(plt.figure(1))
	
	return


#################################################################################################
def PlotExploYears(conn, graphpath, 
				   rangeyear = [1959, datetime.date.today().year], 
				   systems = None):
	"""
	

	Args:
		conn (sqlite_db): database sqlite
		graphpath (str): path and name of the graph to save
		rangeyear (np.array of integers, optional): 2 elements numpy array that gives the range of the years to analyse. Defaults to [1959, datetime.date.today().year].
		systems (list of str, optional): list of specific systems to plot if needed. Defaults to None.
	"""

	# define colors to use; You may add colors if needed
	colores = ['tab:blue', 'tab:red', 'tab:green', 'tab:orange', 'tab:purple', 
			   'tab:marron', 'tab:olive', 'tab:pink', 'tab:cyan']
	
	if systems:
		# Initiate variables
		#somme = pd.DataFrame(columns = ['System', 'Year', 'Longueur'])
		Sy = []
		Yr = []
		Lg = []
		# Loop on the systems and the years
		for system in systems:
			for date in range(rangeyear[0], rangeyear[1]+1):
				# Define SQL query
				lquery = "select sum(LENGTH) from CENTRELINE where SURVEY_ID in (select ID from SURVEY where FULL_NAME LIKE '%s%s%s') and TOPO_DATE between '%s-01-01' and '%s-12-31';" %(chr(37), str(system),chr(37), str(date), str(date))
				junk = pd.read_sql_query(lquery, conn)
				# Update the DataFrame line to line; DEPRECIATED since pandas 2.0
				#somme = somme.append({'System' : system,
				#				  'Year' : int(date),
				#			 	  'Longueur' : junk.to_numpy()[0][0]}, ignore_index = True)
				Sy.append(system)
				Yr.append(int(date))
				Lg.append(junk.to_numpy()[0][0])
				#print(junk)
		somme = pd.DataFrame(list(zip(Sy, Yr, Lg)), columns = ['System', 'Year', 'Longueur'])
		print(max(somme['Longueur']))

		# plot the histogram since the first survey
		fig = plt.figure(1)
		ax1 = fig.add_subplot(111)
		
		fig2 = plt.figure(2)
		ax2 = fig2.add_subplot(111)
		
		# Extract the values for the first system
		sommesys = somme[somme['System'] == systems[0]]
		# Change None values to 0
		sommeplot = sommesys.fillna(0)
		# Remove the column with the names of the systems
		del sommeplot["System"]
		print(sommeplot)

		ax1.bar(sommeplot["Year"], 
		        sommeplot["Longueur"], 
				width = 0.5,
				color = colores[0],
				label = systems[0])
		ax2.bar(sommeplot["Year"], 
		        np.cumsum(sommeplot["Longueur"])/1000, 
				width = 0.5,
				color = colores[0],
				label = systems[0])
		
		# Skip the loop on systems if there is only one system requested --> stacked barplot not needed
		if len(systems) > 1:
			# Check if the number of colors is enough for the numer of systems
			if len(systems)>len(colores):
				raise NameError('\033[91mERROR:\033[00m Number of colors lower than the number of systems!\n\tedit the code to add colors in the list, or lower the number of systems to plot')
			# Copy the lenght column in an other column to trace of it
			sommeplot[systems[0]] = sommeplot["Longueur"]

			for system in systems[1:]:
				# Extract the length for the system
				temp = somme[somme['System'] == system]
				# Replace NaN values by 0 to avoid None values in the sums
				tempplot = temp.fillna(0)
				# Reset the indexes to permit the sum of the length per year
				tempplot.reset_index(inplace = True)
				
				del tempplot["System"]
				# Update the barplot
				ax1.bar(tempplot["Year"],
			    	    tempplot["Longueur"], 
						bottom = sommeplot["Longueur"], 
						width = 0.5,
						color = colores[systems.index(system)], 
						label = system)				

				# Print the cumulative barplot
				ax2.bar(tempplot["Year"], 
			    	    np.cumsum(tempplot["Longueur"])/1000, 
						bottom = np.cumsum(sommeplot["Longueur"])/1000, 
						width = 0.5,
						color = colores[systems.index(system)],  
						label = system)

				# Do the sum of the length, and write it in the length column
				sommeplot["Longueur"] = sommeplot["Longueur"] + tempplot["Longueur"]
				# Copy the length of the system in a new column
				sommeplot[systems[systems.index(system)]] = tempplot["Longueur"]
				

		# Plot mean line
		ax1.axhline(y = somme["Longueur"].mean(), color='red', linestyle='--', label = 'Moy. annuelle')
		ax1.set_xlabel("Année")
		ax1.set_ylabel("Longueur topographiée (m)")
		ax1.legend(loc = 'best')
		# Save the histogram
		fig.savefig(graphpath + "-ExploYear-Reseau.pdf")
		plt.close(plt.figure(1))

		# plot the cumulative histogram since the first survey
		ax2.set_xlabel("Année")
		ax2.set_ylabel("Longueur topographiée cumulée (km)")
		ax2.legend(loc = 'best')
		# Save the cumulative histogram
		fig2.savefig(graphpath + "-ExploYearCum-Reseau.pdf")
		plt.close(plt.figure(1))

	else:
		#somme = pd.DataFrame(columns = ['Year', 'Longueur'])
		Yr = []
		Lg = []
		for date in range(rangeyear[0], rangeyear[1]):
			lquery = "select sum(LENGTH) from CENTRELINE where TOPO_DATE between '%s-01-01' and '%s-12-31';" %(str(date), str(date))	
			junk = pd.read_sql_query(lquery, conn)
			## Depreciated depuis Pandas 2.0
			#somme = somme.append({'Year' : int(date),
			#				 	  'Longueur' : junk.to_numpy()[0][0]}, ignore_index = True)
			Yr.append(int(date))
			Lg.append(junk.to_numpy()[0][0])
		
		somme = pd.DataFrame(list(zip(Yr, Lg)), columns = ['Year', 'Longueur'])


		# plot the histogram since the first survey
		plt.bar(somme["Year"], somme["Longueur"], width = 0.5)
		# plot mean
		plt.axhline(y = somme["Longueur"].mean(), color='red', linestyle='--', label = 'Moy. annuelle')
		plt.xlabel("Année")
		plt.ylabel("Longueur topographiée (m)")
		# Save the histogram
		plt.savefig(graphpath + "-ExploYear.pdf")
		plt.close(plt.figure(1))

		# plot the cumulative histogram since the first survey
		plt.bar(somme["Year"], np.cumsum(somme["Longueur"].fillna(0))/1000, width = 0.5)
		plt.xlabel("Année")
		plt.ylabel("Longueur topographiée cumulée (km)")
		# Save the cumulative histogram
		plt.savefig(graphpath + "-ExploYearCum.pdf")
		plt.close(plt.figure(1))

	return


#################################################################################################
def ExtratSummary(datadb, graphpath, rangeyear = [1959, datetime.date.today().year, 1]):
	# to build a table with, for each year :
	# 	- each centerline surveyed
	#	- Date of the survey
	#	- The network/cave/survey/system
	#	- length surveyed
	#	- length estimated
	#	- length duplicated
	#	- Persons who did the exploration/the survey
	# Need to be ordered by year, then by system, then by caves, and then by network if needed,

	# Needs to play with different queries to get right info and build the right table

	print('\t\tNot Implemented Yet...')

	# extract data
	# 	- each centerline surveyed
	#	- Date of the survey
	#	- The network/cave/survey/system
	#	- length surveyed, by centreline, with the sum by year for the last line of the given year, by system
	#	- length estimated, summed by year/day to avoid multiple lines for each explored cave ? --> Non disponible...
	#	- length duplicated
	#	- Persons who did the exploration/the survey
	# Need to be ordered by year, then by system, then by caves, and then by network if needed,
	# Build the query
	lquery = "test" # To build; do some test !
	
	#lquery = "select NAME, TOPO_DATE, LENGTH, DUPLICATE_LENGHT, NAME, SURNAME from SURVEY, CENTRELINE, TOPO, PERSON group by TOPO_DATE order by 1 desc;"
	#lquery = "select NAME, TOPO_DATE, LENGTH, NAME, SURNAME from SURVEY, CENTRELINE, TOPO, PERSON;"
	
	# Read the database
	#junk = pd.read_sql_query(lquery, conn)

	# Build the structure of the table
	# 1 line = 1 centreline
	# 1 Row = 1 field
	# Do a filter to choose to plot for a specific time-range with a specific bin ?
	#	--> Do a function to extract data ?
	# Do a filter to extract only a single system?

	# Do we need to use/build a dictionnary to write in the table 
	# only the first letters of the name of the people instead of the full names ?
	#	--> Smaller table, much easier to import in a text document ?
	# HEADERS
	# Date / Système / Cavité / Centreline Name / Topographes / L topo / L estimée / L dupliquée / 
	# 			Total JB topo (A la fin de chaque année) / Total JB Estimé (A la fin de chaque année) / 
	# 			Total CP topo (A la fin de chaque année) / Total CP estimé (A la fin de chaque année) / 
	# 			Total A21 topo (A la fin de chaque année) / Total A21 estimé (A la fin de chaque année) / 
	# 			Total AV topo (A la fin de chaque année) / Total AV estimé (A la fin de chaque année) 
	# DERNIEREs LIGNEs si tableau généré pour toute la période d'exploration des Vulcains
	# Total topo/estimé cumulé : sur le Jb, sur la CP, sur le A21, sur les AV et au total sur tout le massif (JB + CP + A21)

	# save the table
	#	Which format ? xlsx ? Pdf ? txt ? Html ?
	#		--> Xlsx OK
	#	sumtable.to_excel(graphpath + "-SummaryTable.xlsx", index = False)
	#		--> Pdf OK


	return


##########################################################################################
def gaussian(x, ampg, meang, sigma1g):
    """
    Function to calculate the Gaussian with constants ampg, meang, and sigmag

    Args:
        x ([float])      : data to describe
        ampg ([float])   : amplitude of the Gaussian
        meang ([float])  : mean of the Gaussian
        sigma1g ([float]): 1-sigma1 of the Gaussian

    Returns:
        1 Gaussian pdf
    """
    
    return ampg * np.exp(-np.power(x - meang, 2)/(2 * np.power(sigma1g, 2)))
    

##########################################################################################
def gaussians(x, *gaussians_param):#amp1, cen1, sigma1, amp2, cen2, sigma2):
    """
    Compute the sum of several Gaussian functions

    INPUTS:
        x ([float])                               : data to desccribe
        gaussians_param (list of floats triplets) : list of tripplets that describes each gaussian pdf
                                                    with the amplitude, the mean and the 1 sigma for each pdf

    RETURNS:
        gaussians_results (np.array of floats): results of the sum of several Gaussian functions.
                                                The size is the same than the input vector x.
    """
    
    # Clear the variable
    gaussians_results = np.zeros(x.shape)
    # Do a loop on the number of peaks --> Determines the number of gaussians to stack
    for h in range(0, int(len(gaussians_param)/3)):
        gaussians_results = gaussians_results + gaussian(x, gaussians_param[3*h], 
                                                            gaussians_param[3*h+1], 
                                                            gaussians_param[3*h+2])

    return gaussians_results


##########################################################################################
def plotgfit(datapdf, pars, ipeak = None):
	"""
	Plot the gaussian fitted with the peak and the 1 sigma error

	Args:
		datapdf (array)           : 1D-pdf data
	    pars (array)              : Gaussian(s) fit results
	    ipeak (integer, optional) : Number of peaks/gaussians. 
	                                Defaults to None.
	"""
    
	if ipeak == 1 : labelname = '1-peak Gaussian fit'
	else: labelname = None
	#print (gaussian(datapdf, pars[0], pars[1], pars[2]))
	plt.plot(gaussian(datapdf, pars[0], pars[1], pars[2]),
			 datapdf,
	        "-b",
	        label = labelname)

	# Colorize the gaussian between the 1 sigmas
	if ipeak == 1 : labelname = 'Acceptable values\n' + '(1\u03C3)'
	else: labelname = None
	#plt.fill_between(gaussian(datapdf, *pars),
	#                 datapdf,
	#				 0,
	#                 where = ((datapdf >= pars[1] - abs(pars[2])) & (datapdf <= pars[1] + abs(pars[2]))),
	#                 alpha=0.30, 
	#                 color='green', 
	#                 interpolate=True,
	#                 label = labelname)
            
	# Plot the mean
	plt.hlines(y = pars[1], 
	           xmin = 0, 
	           xmax = max(gaussian(datapdf, *pars)),
	           colors = 'red',
	           label = 'Mean value %s (%0.1f %s)\n%0.1f +/- %0.1f' %(ipeak, pars[0]*100, chr(37), pars[1], pars[2]))
	#           label = 'Mean value %s (%0.2f %s)\n%0.2f +/- %0.2f' %(ipeak, pars[0]*100, chr(37), pars[1], pars[2]))

	# End of plot
	return


##########################################################################################
def statsparam(shots, graph_path  = 'Graphs/', norm = True,
			   peak_thres = 0.05, peak_min_dist = 30, 
			   size_x = 15, size_y = 15):
	"""
	Function to find the number of gaussian functions, to compute their mean and sigma,
	and to plot the gaussians fit

	INPUTS:
	    shots ([np.array])   : Array of 1D-pdfs for each parameter

	    graph_path (str, optional) : Path where to save graphs and results Usually Graphs.
	                                 Do not forget the '/' at the end.
	                                 Defaults to 'Graphs/'.

	    peak_thres (float, optional): Threshold to find peaks; between 0. and 1.
	                                  Default = 0.05.

	    peak_min_dist (interger, optional): Minimum distance between the peaks
	                                        Default = 30.

	    size_x (int, optional): Size of the font for the x axes label. 
	                            Defaults to 15.

	    size_y (int, optional): Size of the font for the y axes label. 
	                            Defaults to 15.

	"""

	## Find the non-parametric pdf of the distribution
	if norm :
		nparam_density = stats.gaussian_kde(dataset = shots['(S1.Z+S2.Z)/2'].values.ravel(),
										bw_method=0.05,
										weights = shots['Norm_LENGTH'])
	else:
		nparam_density = stats.gaussian_kde(dataset = shots['(S1.Z+S2.Z)/2'].values.ravel(),
											bw_method=0.05,
											weights = shots['LENGTH'])
	shots_pdf = nparam_density.pdf(shots['(S1.Z+S2.Z)/2'].values.ravel())

	# initiate fig
	plt.clf()
	# print the 1D-pdf
	plt.plot(shots_pdf, shots['(S1.Z+S2.Z)/2'].values.ravel(), "mo", label = 'pdf')

	# find number of peaks/gaussian
	indexes = peakutils.indexes(shots_pdf, 
	                            thres = peak_thres, # Normalized threshold. Only the peaks with amplitude higher than the threshold will be detected.
	                            min_dist = peak_min_dist)
	                            
	print('\t\tNumber of peak(s) : %s' %(indexes.shape[0]))

	# Fit the Gaussian data
	# Compute the mean and 1 sigma erro used for the first guess of the fit
	mean = sum(shots['(S1.Z+S2.Z)/2'].values.ravel() * shots_pdf) / sum(shots_pdf)
	sigma = np.sqrt(sum(shots_pdf * (shots['(S1.Z+S2.Z)/2'].values.ravel() - mean) ** 2) / sum(shots_pdf))
	# REM: to avoid RuntimeError from curve_fit, it is easier to divide sigma by ~10;
	#      this is done inside the curve_fit parameters
	
	# Do the fitting
	try:
		# pars : triplet with amplitude, the mean and the 1 sigma for each pdf
		pars, cov = curve_fit(f = gaussians,
	 	                    xdata = shots['(S1.Z+S2.Z)/2'].values.ravel(), ydata = shots_pdf, 
							#xdata = shots['LENGTH'].values.ravel(), ydata = shots_pdf, 
	 	                    #p0 = np.array([np.stack([shots_pdf[indexes[k]],
	 						# 				shots['(S1.Z+S2.Z)/2'].iloc[indexes[k]], 
	 						# 				sigma/10])
	 						p0 = np.array([np.stack([shots_pdf[indexes[k]],
	 												shots['(S1.Z+S2.Z)/2'].iloc[indexes[k]], 
	 												sigma/10])
	 	                                  for k in range(0, indexes.shape[0])]).reshape(-1),
	 	                    bounds=(-np.inf, np.inf),
	 	                    check_finite = True)
	 	                    #maxfev = 5000)
		i_opt = True
	except RuntimeError:
	 	print(u'\t\t\033[91mWarning:\033[00m No optimization found with the least-square method; I am trying the dogbox method')
	 	try:
	 		pars, cov = curve_fit(f = gaussians,
	 		                    xdata = shots['LENGTH'].values.ravel(), ydata = shots_pdf, 
	 		                    #p0 = np.array([np.stack([shots_pdf[indexes[k]],
	 							# 				shots['(S1.Z+S2.Z)/2'].iloc[indexes[k]], 
	 							# 				sigma/10])
	 							p0 = np.array([np.stack([shots_pdf[indexes[k]],
	 													shots['(S1.Z+S2.Z)/2'].iloc[indexes[k]], 
	 													sigma/10])
	 		                                  for k in range(0, indexes.shape[0])]).reshape(-1),
	 		                    bounds=(-np.inf, np.inf),
	 		                    check_finite = True,
	 		                    method = 'dogbox',
	 		                    maxfev = 5000)
	 		i_opt = True
	 	except RuntimeError:
	 		print(u'\t\t\033[91mWarning:\033[00m No optimization found also with the dogbox method; No graph will be produced')
	 		i_opt = False
	 		pass

	if i_opt:
		# Get the standard deviations of the parameters (square roots of the diagonal of the covariance)
		stdevs = np.sqrt(np.diag(cov))
		# Calculate the residuals
		res = shots_pdf - gaussians(shots['(S1.Z+S2.Z)/2'], *pars)
		
		xerror = (max(shots['(S1.Z+S2.Z)/2']) - min(shots['(S1.Z+S2.Z)/2'])) / 2

		for k in range(0,indexes.shape[0]):
			# Compute the result for each peak
			pars_1 = pars[(3*k) : (3*k+3)]

			if (pars_1[1] > (min(shots['(S1.Z+S2.Z)/2']) - xerror)) & (pars_1[1] < (max(shots['(S1.Z+S2.Z)/2'] + xerror))):
	 			# print on screen results
	 			print('\t\tMean & sigma (Gaussian fit %s, %0.2f %s) : %0.2f +/- %0.2f' %(str(k+1), pars_1[0]*100, chr(37), pars_1[1], abs(pars_1[2])))
	 			# Save the results in text file for each peak
	 			#line = (str(param[i]) + 'peak ' + str(k+1) + '\t' + str(pars[1]) + '\t' + str(stdevs[1]) +
	 			#                       '\t' + str(pars[2]) + '\t' + str(stdevs[2]) +
	 			#                       '\n')
	 			#fstats_w.write(line)
	 			# Plot the gaussian fitted
	 			if pars_1[0] > 0:
	 				plotgfit(datapdf = shots['(S1.Z+S2.Z)/2'], pars = pars_1, ipeak = k+1)
	 			else:
	 				print(u'\t\t\t\033[91mWarning:\033[00m Negative amplitude for the fit...\n\t\t\t\033[91m-->\033[00m Not plotted')
			else:
	 			print(u'\t\t\t\033[91mWarning:\033[00m peak value (%s) outside of acceptable bounds ...\n\t\t\t\033[91m-->\033[00m Not plotted' %(pars_1[1]))

	# Set axis names
	plt.ylabel("Shots' altitude (m)", fontsize=size_x)
	plt.xlabel('Probability', fontsize=size_y)
	#plt.xlim(min(shots['(S1.Z+S2.Z)/2']), max(shots['(S1.Z+S2.Z)/2']))
	#plt.ylim(0, None)
	plt.legend(loc = 'best')

	# Saving the plots as a pdf file
	plt.savefig(graph_path + '-PDF-1D.pdf')
	plt.clf()

	## close the output text file
	#fstats_w.close()

	return

#################################################################################################
def Shot_lengths_altitude(conn, graphpath, altbins = 20, altmin = None, altmax = None, gradient_threshold = None):
	"""
	Plot the histogram of the cumulated lengths of the shots function of the altitude for the entire database

	Args:
		conn (sqlite_db)                    : database sqlite
		graphpath (str)                     : path and name of the graph to save
		altbins (int, optional)             : altitude's range of a bin. Defaults to 20.
		altmin (float, optional)            : altitude minimum of the analysis. Defaults to None.
												if None, the min altitude value is extracted from the database.
		altmax (float, optional)            : altitude maximum of the analysis. Defaults to None.
												if None, the max altitude value is extracted from the database.
		gradient_threshold (float, optional): gradient threshold to limit the analysis 
											  to the shots with lower gradient than the thresholh. 
											  Defaults to None.
	"""
		
	# Get the minimum and the maximum altitude range
	if not altmin or not altmax:
		dfstations = pd.read_sql_query("select * from STATION;", conn)
		if not altmin:
			altmin = int(dfstations['Z'].min())
		if not altmax:
			altmax = int(dfstations['Z'].max()) + 1
	
	# Extract the usefull data from the global database
	selection = "select SHOT.ID, S1.NAME, S2.NAME, LENGTH, (S1.Z+S2.Z)/2, GRADIENT, BEARING \
					from SHOT, STATION S1, STATION S2 \
						where SHOT.FROM_ID = S1.ID and SHOT.TO_ID = S2.ID \
							and not S2.NAME = '-' and not S2.NAME = '.';"
	shotstot = pd.read_sql_query(selection, conn)

	# Remove duplicates and surface data
	print('\tRemoving surface and duplicate data...')
	selection = "select SHOT_ID, FLAG from SHOT_FLAG;"
	shots_flags = pd.read_sql_query(selection, conn)
	# Find correspondance between the 2 databases, and remove the shots who ahe a flag
	shots = shotstot.drop(shotstot[shotstot['ID'].isin(shots_flags['SHOT_ID'])].index)	
	if len(shots) < len(shotstot):
		print('\t%s shots removed (surface ant duplicate data) corresponding to %s m' %(len(shotstot[shotstot['ID'].isin(shots_flags['SHOT_ID'])]), sum(shotstot[shotstot['ID'].isin(shots_flags['SHOT_ID'])]['LENGTH'])))
	# Add a column with the length of the shots normalized to the cumulated length
	shots['Norm_LENGTH'] = shots['LENGTH']/sum(shots['LENGTH'])

	# DO some STATS !
	#statsparam(shots = shots, graph_path  = graphpath, norm = False,
	#		   peak_thres = 0.05, peak_min_dist = 50,
	#		   size_x = 15, size_y = 15)

	# Do the plot of the distribution
	if not gradient_threshold:
		g = sns.displot(data = shots,
					y = '(S1.Z+S2.Z)/2', 
					weights = 'LENGTH',
					#stat = 'probability', 
					#bins = int((altmax-altmin)/altbins),
					binwidth = altbins,
					binrange = (altmin, altmax), 
					kind = 'hist',
					alpha = 0.5,
					kde = True,
					kde_kws={'clip'     : (altmin, altmax),
							 #'weights'  : 'LENGTH',
							 'bw_adjust': 0.2})
	else:
		g = sns.displot(data = shots[abs(shots['GRADIENT'] <= gradient_threshold)],
					y = '(S1.Z+S2.Z)/2', 
					weights = 'LENGTH',
					#stat = 'probability', 
					#bins = int((altmax-altmin)/altbins),
					binwidth = altbins,
					binrange = (altmin, altmax), 
					kind = 'hist',
					alpha = 0.5,
					kde = True,
					kde_kws={'clip'     : (altmin, altmax),
							 #'weights'  : 'LENGTH',
							 #'bw_adjust': })
							 'bw_adjust': 0.2})
		g.axes[0][0].text(0.82, 0.90, 'Grad. threshold = %s°' %(str(gradient_threshold)), style='italic',
				horizontalalignment='right', verticalalignment='center',
				transform=g.axes[0][0].transAxes)
	
	# Find and print peaks
	## Find Peaks
	xx, yy = g.axes[0, 0].lines[0].get_data()
	indexes = peakutils.peak.indexes(xx, thres = 0.02, min_dist = 5)
	## Plot Peaks
	if indexes.size > 0:
		#ax = pplot(xx, yy, indexes)
		for i in range(len(indexes)):
			g.axes[0][0].hlines(yy[indexes[i]], 
								xmin = 0, xmax = xx[indexes[i]], 
								colors = 'red', alpha = 0.7,
								linewidth = 0.8)
			g.axes[0][0].text(-5, yy[indexes[i]], str(int(yy[indexes[i]])),
							  fontsize = 7, color = 'red',
							  horizontalalignment = 'right', verticalalignment = 'center')
			# Essayer de faire un plot de pdf pour chaque pic, en transparence (alpha = 0.3 ?)
			# centrée sur le pic, avec la valeur max du pic
			#x_pdf = np.linspace(altmin, altmax, 100)
			#y_pdf = scipy.stats.norm.pdf(x_pdf)
		#ax.get_legend().remove()

	else:
		print('\t\tNO Peaks')


	g.axes[0][0].text(0.82, 0.95, 'Altitude range bin = %s m' %(str(altbins)), style='italic',
			horizontalalignment='right', verticalalignment='center',
			transform=g.axes[0][0].transAxes)
	g.set_axis_labels("Cummulated length (m)", "Shot's altitude (m)")
	
	# Save and close the graph
	plt.savefig(graphpath + "-cum_lengths_Alt_histogram.pdf")
	plt.close(plt.figure(1))

	##### Next lines are to test the kde parameters extraction
	#from sklearn.neighbors import KernelDensity

	## Instantiate and fit the KDE model
	#kde = KernelDensity(bandwidth=0.2, kernel = 'gaussian')
	#kde.fit(shots['(S1.Z+S2.Z)/2'])
	#print((shots['(S1.Z+S2.Z)/2'].plot.kde().get_lines()[0].get_xydata()).shape)

	return

#################################################################################################
#################################################################################################

def PlotThStats(inputfile, graphfolder = "Graphs/", 
				graphprefix = None, 
				bins = 72, log = None, 
				rangeyear = None, 
				systems = None,
				altbins = 20,
				altmin = None,
				altmax = None,
				gradient_threshold = None):
	"""
	Function to call all the other functions to plot the Therion database.
	Before to run this function, you need to change the encoding of the database with sqlite3.
		For a database.sql, in a terminal, run :
			sqlite3 database_new.sql
			sqlite> .read database.sql

	Args:
		inputfile (str): path and name of the sql database to analyse/plot
		graphfolder (str, optional): name of the folder wher we save the graphs. Defaults to "Graphs/".
		graphprefix (str, optional): prefix for the graphs' names. Defaults to None.
		bins (int, optional): bins for the plot. Defaults to 72.
		log (str, optional): set it to 'log' to use a y-logscale. Defaults to None.
		rangeyear (np.array of integers, optional): 2 elements numpy array that gives the range of the years to analyse. Defaults to None.
		systems (list of str, optional): list of specific systems to plot if needed. Defaults to None.
		altbins (int, optional)             : altitude's range of a bin. Defaults to 20.
		altmin (float, optional)            : altitude minimum of the analysis. Defaults to None.
												if None, the min altitude value is extracted from the database.
		altmax (float, optional)            : altitude maximum of the analysis. Defaults to None.
												if None, the max altitude value is extracted from the database.
		gradient_threshold (float, optional): gradient threshold to limit the analysis 
											  to the shots with lower gradient than the thresholh. 
											  Defaults to None.

	Raises:
		NameError: error with the input file; see the description when the error is raised.
	"""
	
	print(' ')
	print(' ')
	print('******************************************')
	print('Program to plot Therion statistics')
	print('     Written by X. Robert, ISTerre')
	print('             2022 - 2024      ')
	print('******************************************')
	
	# check if input file exists
	if not os.path.isfile(inputfile):
		raise NameError('\033[91mERROR:\033[00m File %s does not exist' %(str(inputfile)))
	# Test if the file is in the correct format; Otherwise, explain how to get rid of it
	try:
		df = pd.read_sql_query("select * from CENTRELINE;", sqlite3.connect(inputfile))
	except:
		raise NameError('\033[91mERROR:\033[00m The %s database is not a valid database...\n\tYou need to update its structure to a _new database:\n\tIn a terminal by typing:\n\t\tsqlite3 %s_new.sql\n\t\tsqlite> .read %s\n\n' %(inputfile, inputfile[:-4], inputfile))

	# Check if there is a folder to store the outputs
	print('\x1b[32;1m\nPlotting results...\x1b[0m')
	if not os.path.exists(graphfolder):
		print('\tMaking %s...' %(str(graphfolder)))
		os.mkdir(graphfolder)
	else:
		print('\t%s already exists...' %(str(graphfolder)))

	if not graphprefix: graphprefix = inputfile[:-4]
	graphpath = os.path.join(graphfolder, graphprefix)

	if systems:
		Nb = 7
	else:
		Nb = 6
	# Define the progress-bar
	with alive_bar(Nb, title = "\x1b[32;1m- Processing...\x1b[0m", length = 35) as bar:
		# Load the Therion database
		print('\tReading database')
		datadb = sqlite3.connect(inputfile)
		# Update the progress-bar
		bar()

		# Plot the Rose diagram
		print('\tPlotting Rose diagram')
		Rose(datadb, graphpath, bins)
		# Update the progress-bar
		bar()

		# Plot the shot lengths histogram
		print('\tPlotting lengths histogram')
		#Shot_lengths_histogram(datadb, graphpath, bins, log)
		# Update the progress-bar
		bar()

		# Plor the cumulated shot length in function of altitude
		print('\tPlotting cumultated shot lengths function of altitude')
		if not altbins:
			altbins = 20
		Shot_lengths_altitude(datadb, graphpath, altbins, altmin, altmax, gradient_threshold)
		# Update the progress-bar
		bar()

		# Plot the length over years
		print('\tPlotting global survey evolution')
		#PlotExploYears(datadb, graphpath, rangeyear = rangeyear)
		# Update the progress-bar
		bar()
		#if systems:
		#	# Plot the length over years per karstic system
		#	print('\tPlotting survey evolution system by system')
		#	PlotExploYears(datadb, graphpath, rangeyear = rangeyear, systems = systems)
		#	# Update the progress-bar
		#	bar()

		# Extract summary table
		print('\tExtract summary table')
		ExtratSummary(datadb, graphpath, rangeyear = [1959, datetime.date.today().year, 1])
		# Update the progress-bar
		bar()

	datadb.close()

	print('')
	print('')



if __name__ == u'__main__':	
	###################################################
	# initiate variables
	#inputfile = 'TestJB.sql'
	#inputfile = 'TestCP7.sql'
	#inputfile = 'databaseLDB.sql'
	inputfile = 'database-new.sql'

	graphfolder = "Graphs" 
	#graphprefix = None
	#bins = 144
	#log = "log"

	rangeyear = [1959, datetime.date.today().year]
	#rangeyear = None

	#systems = ['SynclinalJB.MassifFolly', 'SystemeCP.MassifFolly', 'SystemeA21.MassifFolly', 'SystemeAV.MassifFolly']
	#systems = ['SynclinalJB', 'SystemeCP', 'SystemeA21', 'SystemeAV']
	#systems = ['SynclinalJB', 'SystemeCP', 'SystemeA21', 'SystemeAV', 'SystemMirolda']
	systems = None

	# Variable for the cumulative length in function of altitude bins
	# altbins: difference of altitude for each bin, in meters
	#			If not given or None, default is 20 m
	altbins = 5
	# altmin, altmax: altitude range of analysis
	#				  If not given or None, this will be calculated from the database
	altmin = 250
	altmax = 1550
	# gradient_threshold: threshold value to do the analysis only for gradient values lower than this threshold (degrees)
	gradient_threshold = 10
	#gradient_threshold = None

	###################################################
	# Run the plots
	PlotThStats(inputfile, graphfolder = graphfolder, 
				rangeyear = rangeyear, systems = systems,
				altbins = altbins, altmin = altmin, altmax = altmax, gradient_threshold = gradient_threshold)
	# End...
