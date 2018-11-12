import PIL
from PIL import ImageFont
from PIL import Image
from PIL import ImageDraw
import cv2;
import numpy as np;
import os;
from math import *
import sys


char = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
         "A","B", "C", "D", "E", "F", "G", "H","I", "J", "K",
         "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X","Y", "Z"];

def rot(img, angel, shape, max_angel):
    """
        Apply affine trasformation to the image.
        This function is obtained from https://github.com/huxiaoman7/mxnet-cnn-plate-recognition
    """
    size_o = [shape[1], shape[0]]
    size = (shape[1] + int(shape[0] * cos((float(max_angel) / 180) * 3.14)), shape[0])
    interval = abs(int(sin((float(angel) / 180) * 3.14) * shape[0]));
    pts1 = np.float32([[0, 0], [0, size_o[1]], [size_o[0], 0], [size_o[0], size_o[1]]])
    if (angel > 0):
        pts2 = np.float32([[interval, 0], [0, size[1]], [size[0], 0], [size[0] - interval, size_o[1]]])
    else:
        pts2 = np.float32([[0, 0], [interval, size[1]], [size[0] - interval, 0], [size[0], size_o[1]]])
    M = cv2.getPerspectiveTransform(pts1, pts2);
    dst = cv2.warpPerspective(img, M, size);
    return dst


def rotRandrom(img, factor, size):
    """
        Apply perspective trasformation to the image.
        This function is obtained from https://github.com/huxiaoman7/mxnet-cnn-plate-recognition
    """
    shape = size;
    pts1 = np.float32([[0, 0], [0, shape[0]], [shape[1], 0], [shape[1], shape[0]]])
    # pts2 = np.float32([[r(factor), r(factor)], [ r(factor), shape[0] - r(factor)], [shape[1] - r(factor),  r(factor)],
    #                    [shape[1] - r(factor), shape[0] - r(factor)]])
    pts2 = np.float32([[factor, factor], [factor, shape[0] - factor], [shape[1] - factor, factor],
                       [shape[1] - factor, shape[0] - factor]])
    M = cv2.getPerspectiveTransform(pts1, pts2);
    dst = cv2.warpPerspective(img, M, size);
    return dst


def tfactor(img):
    """
        Add noise on hsv channel.
        This function is obtained from https://github.com/huxiaoman7/mxnet-cnn-plate-recognition
    """
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV);
    hsv[:, :, 0] = hsv[:, :, 0] * (0.8 + np.random.random() * 0.2);
    hsv[:,:,1] = hsv[:,:,1]*(0.3+ np.random.random()*0.7);
    hsv[:,:,2] = hsv[:,:,2]*(0.2+ np.random.random()*0.8);
    img = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR);
    return img


def random_envirment(img, data_set):
    """
        Add random environment background on the image.
        This function is obtained from https://github.com/huxiaoman7/mxnet-cnn-plate-recognition
    """
    index = r(len(data_set))
    env = cv2.imread(data_set[index])
    env = cv2.resize(env, (img.shape[1], img.shape[0]))
    bak = (img == 0);
    bak = bak.astype(np.uint8) * 255;
    inv = cv2.bitwise_and(bak, env)
    img = cv2.bitwise_or(inv, img)
    return img


def AddGauss(img, level):
    """
        Apply Gaussian blur to the image.
        This function is obtained from https://github.com/huxiaoman7/mxnet-cnn-plate-recognition
    """
    return cv2.blur(img, (level * 2 + 1, level * 2 + 1));


def r(val):
    """
        Generate random integer.
        This function is obtained from https://github.com/huxiaoman7/mxnet-cnn-plate-recognition
    """
    return int(np.random.random() * val)



def AddNoiseSingleChannel(single):
    """
        Add single channel Gaussian noise on the image.
        This function is obtained from https://github.com/huxiaoman7/mxnet-cnn-plate-recognition
    """
    diff = 255 - single.max();
    noise = np.random.normal(0, 1 + r(6), single.shape);
    noise = (noise - noise.min()) / (noise.max() - noise.min())
    noise = diff * noise;
    noise = noise.astype(np.uint8)
    dst = single + noise
    return dst


def addNoise(img, sdev=0.5, avg=10):
    """
        Add Gaussian noise on the image.
        This function is obtained from https://github.com/huxiaoman7/mxnet-cnn-plate-recognition
    """
    img[:, :, 0] = AddNoiseSingleChannel(img[:, :, 0]);
    img[:, :, 1] = AddNoiseSingleChannel(img[:, :, 1]);
    img[:, :, 2] = AddNoiseSingleChannel(img[:, :, 2]);
    return img



def drawChar(font, char):
    charImg = Image.new("RGB", (22, 65), (255, 255, 255))
    draw = ImageDraw.Draw(charImg)
    r = 164
    g = 186
    b = 209
    draw.text((0, 2), char.decode('utf-8'), (255 - r, 255 - g, 255 - b), font=font)
    charImg = np.array(charImg)
    return charImg


def drawPlateNum(font, plate_number):
    plateNumImg = np.array(Image.new("RGB", (226, 70), (255, 255, 255)))
    x_offset = 12;
    for i in range(6):
        x_pos = x_offset + i * 22 + i * 7;
        if i > 2:
            x_pos += 32
        plateNumImg[5:70, x_pos: x_pos + 22] = drawChar(font, plate_number[i]);

    return plateNumImg

font = ImageFont.truetype('./font/VicLicensePlate.ttf', 50, 0);
plate_template = cv2.resize(cv2.imread("./template/VIC_template.jpg"), (226, 70));
enviroment_bg = ["./env/"+file for file in os.listdir("./env")];
n_plates = 100
train_label_file = "train_label.txt"
test_label_file = "test_label.txt"
label = open(train_label_file, 'w')
train_plate_dir= "./plate/train"
test_plate_dir= "./plate/test"
plate_dir = train_plate_dir
for i in xrange(n_plates):
    if i == int(n_plates *9/ 10):
        label = open(test_label_file, 'w')
        plate_dir = test_plate_dir
    plate_number = ""
    plate_number_index = np.random.randint(0,len(chars),size = 6)
    plate_number_char = ""
    for j in plate_number_index:
        plate_number_char += chars[j]
    print str(i).zfill(2), plate_number_char
    plate_num = drawPlateNum(font, plate_number_char);
    img = cv2.bitwise_xor(cv2.bitwise_not(plate_num), plate_template);
    img = rot(img, np.random.randint(0,60) - 30, img.shape, 30);
    img = rotRandrom(img, 3, (img.shape[1],img.shape[0]));
    img = tfactor(img)
    img = random_envirment(img, enviroment_bg);
    img = AddGauss(img, 1 + np.random.randint(0,2));
    img = addNoise(img);
    img = cv2.resize(img, (164, 48));
    cv2.imwrite(plate_dir+ "/" + i + ".jpg", img);
    label.write(i + ".jpg" + ":" + plate_number_char + "\n")
