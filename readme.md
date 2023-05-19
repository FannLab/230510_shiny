1. 這裡需要陳老師幫忙修改，介紹PairNet
2. 這個github repo稍晚會刪掉，重建一個新的，目前是測試版本
3. PairNet-shiny這個名稱可以嗎?還是有其他建議


## NOTE
  
This is a demo webpage of PairNet built using R Shiny. The current functionalities of the webpage include:

Displaying Demo Data and Results: The webpage showcases some demo data for users to reference and displays the results of running PairNet, allowing users to understand the effectiveness of PairNet.

Uploading Files and Running PairNet: Users can utilize the functionality on the webpage to upload files of their choice and run the PairNet algorithm. This feature enables users to apply their own data to PairNet and view the results.




## Prerequisite
This Shiny program utilizes both R and Python, so please ensure that the user's computer has R and Python installed. The following are the R packages used:

* caret
* shiny
* data.table
* reticulate
* pROC
* jpeg
* waiter
* shinyvalidate

And the Python packages used are:

* torch
* math
* pandas
* numpy
* matplotlib
* sklearn
* tqdm.auto
* copy
* re

Please note that some packages may already be pre-installed in the system. Please check if any of these packages are missing and install them if necessary.

## Installation
You can download the entire repo with the following command:
```
git clone https://github.com/FannLab/230510_shiny.git
```

You can also refer to the [RStudio website](https://shiny.posit.co/r/deploy) to choose the deployment method that suits your needs.

## Using

In the repo, there are a few points to note:

1.  This program utilizes the R `reticulate` package to call Python. Therefore, you need to specify the location of Python in the R file `app.R`. Find the following line:
```
python_file <- file.path("C:","Users","cs210","anaconda3","python.exe")
```
Modify the location to match your Python installation.

2.  In the current version, GPU is not used. If you want to utilize GPU, locate the line in the `app.R` file:
```
script_file <- file.path('script','train_val_test.py')
```
Change it to:

```
script_file <- file.path('script_gpu','train_val_test.py')
```


### Citation