#%matplotlib inline
import sys
#sys.path.append("/home/jupyter/shared/pypulse") #temporary
sys.path.append("/home/jovyan/development/")
sys.path.append("/home/jovyan/work/shared/")
from nanograv_data.api.nanograv_api import NANOGravAPI
api = NANOGravAPI()
from nanograv_utils import NANOGravUtils
utils = NANOGravUtils()#import numpy as np

