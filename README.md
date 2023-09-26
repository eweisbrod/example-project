![example-project](https://socialify.git.ci/eweisbrod/example-project/image?description=1&font=Inter&forks=1&issues=1&name=1&owner=1&pattern=Solid&pulls=1&stargazers=1&theme=Light)

This repository (repo) provides a template for an Accounting / Finance research project. It covers the following steps using a very basic earnings persistence regression as an example:

1. Installing Git and R
2. Downloading data from WRDS using R OR SAS
3. Saving data to a Stata file using R OR SAS
4. Creating Figures using R
5. Creating a full set of VERY PRETTY tables using R OR Stata
    * Manual tables
    * Cross-tab
    * Descriptive Statistics
    * Correlation Matrix
    * Regression (with dynamic FE indicators, etc)
6. Outputing the tables to LaTeX OR MS Office
   * Overleaf LaTeX template included: <https://www.overleaf.com/read/ctmwnmdcypzh>
   * [Example PDF for the LaTeX tables](./assets/Paper_Template.pdf)


## Table of Contents

* [Introduction](#intro)
* [How to Use These Materials](#usethese)
* [Getting Started with R and Git](#getstart)
* [Forking This Repository](#fork)
* [Additional Resources](#links)

##  <a name="intro"></a>Introduction 

The goal of this example is to help researchers go from zero to producing a publication-ready research document as quickly as possible. A secondary goal is to provide good table-formatting examples to assist PhD students and junior colleages in preparing nice-looking tables for our research projects. This website began as an example of how to code a basic research project entirely in R, but has expanded to provide equivalent code for users that prefer SAS or Stata. 

My recommendation for managing your research project is to anchor your project in R, and manage your code on Github. Github offers private repositories for academic users if your code is proprietary. Github also offers great version control and search functionality. Your data can be stored and shared separately, perhaps using an online backup and file sharing service such as Dropbox or OneDrive. The example code in this repository gives examples for setting up references to a shared data directory with coauthors. R can easily read in both SAS and Stata files, and easily output to Stata if needed. Personally, I still do some of my initial data collection in SAS, and then move the data to R for analyses. I don't enjoy working in Stata, but I have included a Stata version of the code for reference. You may encounter coauthors that are only comfortable collaborating in Stata. If you do your analyses and table creation in Stata, I recommend to at least learn a little bit of R for creating figures. Making figures in R is more intuitive than in Stata and the figures look nicer. You can read your Stata dataset into R and make some nice figures that will really enhance your research project. 

I have put greater emphasis on the "last mile" of table creation and formatting as compared with "learning to code" or learning the ins-and-outs of various financial data. Therefore, users may want to take a look at these materials, go somewhere else to fill in the holes, and then come back to them when they are starting to output tables. I use these materials in conjunction with in-person instruction, so there might be parts that are not completely self-standing on the website. There is a very bare-bones attached slide deck with some of the discussion material that I cover in-person. Please always feel free to reach out to me with any questions about the material or suggestions for additional instructions.

## <a name="usethese"></a> How To Use These Materials 
Please feel free to use these materials in your work or share them with others.

I recommend that you "fork" this repository to your own GitHub account and then "clone" the files down to a local folder on your computer [(see below)](#fork). This will help you understand Git, and you can customize the files as needed.  

You can also download all of the files in the repo as a zip file by clicking [here](https://github.com/eweisbrod/example-project/zipball/main).

Of course, you can also simply browse through the code on GitHub in your web browser and either download or copy/paste any parts that are useful to you.
If you are viewing this on the ".io" website, there is a "view in GitHub button above." If you are viewing this on GitHub, the folder structure appears above this ReadMe content.
You can also click the "Code" tab at the top of the page if needed.

Files are organized as follows:
*   The src folder contains the relevant SAS, R, and Stata code
*   The assets folder contains an optional RStudio theme and font, slide deck, website images, etc.

### Citing Me
Please leave a link / attribution to this repository when sharing it with others. If you are able to work in a citation to one of my recent papers, that would help me out!

* Some of the code in this repo was developed for Bochkay et al. (2022), so it would be appropriate to cite it as a source of the coding examples:
   * BOCHKAY, K., MARKOV, S., SUBASI, M. and WEISBROD, E. (2022), The Roles of Data Providers and Analysts in the Production, Dissemination, and Pricing of Street Earnings.
Journal of Accounting Research, 60: 1695-1740. <https://doi.org/10.1111/1475-679X.12457>
   * [Code Appendix](https://www.chicagobooth.edu/research/chookaszian/journal-of-accounting-research/online-supplements-and-datasheets/volume-60)

* Alternately, you could cite my dissertation paper:
   * WEISBROD, E. (2019), Stockholders' Unrealized Returns and the Market Reaction to Financial Disclosures. The Journal of Finance, 74: 899-942. <https://doi.org/10.1111/jofi.12743>

##  <a name="getstart"></a>Getting Started with R and Git

In order to "clone" (copy) this repository to your machine and run the R code, you will need to install Git, R, RStudio, and several R packages to your machine.
I will provide the installation steps for a Windows machine, but the steps are very similar for MacOS or Linux.

### 1. Install Git

-   Follow the steps at this link: <https://git-scm.com/book/en/v2/Getting-Started-Installing-Git>

I think it is a good idea to allow this option to install git into your PATH so that RStudio can find it.

![git install 1](assets/images/git1.jpg)

It is also helpful to allow git to install the credential manager to help with storing your github credentials.

![git install 2](assets/images/git2.jpg)

-   Finally, I also recommend to install / allow Git bash during the installation.

### 2. Install R

-   Before you install RStudio, you should first install R from the following link: <https://cran.rstudio.com/>

If you already have R on your machine, I recommend at least R version 4.0 or better to follow along with the code in this repo.
If you use an older version of R, you may see some warnings about R packages being built with a different version, but usually everything will still work.

### 3. Install RStudio

-   Install RStudio Desktop from the following link: <https://www.rstudio.com/products/rstudio/download/#download>

![rstudio install](assets/images/rstudio1.jpg)

As shown in the screenshot, R should be installed first, as we did in the previous step.

### 4. Sign up for a Github account

-   If you have not done so already, register for an account at <https://github.com/>

-   There are some benefits to linking your Github account to your school email (<https://education.github.com/benefits>).

-   Below, I recommend that you use the same primary email address that you use for github when you set your user.email in git.
    You can use a personal email as your primary email on Github and also link your Github account to your (secondary) school email as well, if desired.

### 5. Open RStudio and set your Git credentials

-   To work with Git, you need to set your user name and email.
-   There are many ways to do this, but an easy way is using RStudio's built-in terminal.

![rstudio terminal](assets/images/terminal1.jpg)

-   Click on the "terminal" tab that should be next to console.
-   Type the following commands

```         
git config --global user.email "your@email.com"
```

```         
git config --global user.name "Your Name"
```

-   NOTE: If this step doesn't work, don't worry. Just keep going. This might not work if you did not install Git bash, but you should still be able to keep going.

##  <a name="fork"></a>Forking this Repository 




-   <b><ins> IMPORTANT: You need to create a local directory to hold the local copy of this repository on your computer.
    DO NOT put this directory inside Dropbox.
    Dropbox and Git do not play well together unless you are an advanced user.
    I recommend to use a simple directory on your main drive that is easy to find.
    </b></ins>

-   At the top of this page, click the green code button and copy the https link to this repo.

![clone repo](assets/images/clone1.jpg)

-   In RStudio, click File -\> New Project.
    On the next menu, click "Version Control" and choose Git.

-   Paste the URL into the box, as follows:

![clone repo2](assets/images/clone2.jpg)

-   Click "Create Project"

<p><b> 7.
Open the "--Install-Packages.R" script in the "src" folder in RStudio </b></p>

-   Run the commands in this file by highlighting them and pushing "ctrl+Enter" or by highlighting them and clicking "run."
-   If you are able to successfully connect to WRDS you should see a line like this output in your console:

![postgres](assets/images/postgres.PNG)

-   If you were able to successfully install the packages and connect to WRDS, you should now be ready to follow along for the coding workshop.

##  <a name="links"></a>Introduction 
