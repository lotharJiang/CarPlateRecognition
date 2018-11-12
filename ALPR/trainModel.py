import cv2
import numpy as np
from keras.models import *
from keras.layers import *

char = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
         "A","B", "C", "D", "E", "F", "G", "H","I", "J", "K",
         "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X","Y", "Z"];

index = {"0":0, "1":1, "2":2, "3":3, "4":4, "5":5, "6":6, "7":7, "8":8, "9":9,
         "A":10,"B":11, "C":12, "D":13, "E":14, "F":15, "G":16, "H":17,"I":18, "J":19, "K":20,
         "L":21, "M":22, "N":23,"O":24, "P":25, "Q":26, "R":27, "S":28, "T":29, "U":30, "V":31, "W":32, "X":33,"Y":34, "Z":35};


def getData(filename):
    x =[]
    y =[]
    with open(filename) as f:
        for line in f:
            imageName,label = line.split(":")
            x.append(cv2.imread("./plate/train/"+imageName))
            onehot_label = np.zeros([18,len(char)+1])
            onehot_label[:,-1:] = np.ones([18,1])
            for i in xrange(6):
                offset = 4
                if i >3:
                    offset += 6
                onehot_label[i+offset][index[label[i]]] = 1
                onehot_label[i + offset][len(char)] = 0
            y.append(onehot_label)
    x = np.array(x)
    x = np.transpose(x, axes=[0, 2, 1, 3])
    y= np.array(y)
    return x,y


x = Input(shape =(164,48, 3), dtype='float32')
cnn1 = Conv2D(32, (3, 3))(x)
cnn1 = BatchNormalization()(cnn1)
cnn1 = Activation('relu')(cnn1)
cnn1 = MaxPooling2D(pool_size=(2, 2))(cnn1)
cnn2 = Conv2D(64, (3, 3))(cnn1)
cnn2 = BatchNormalization()(cnn2)
cnn2 = Activation('relu')(cnn2)
cnn2 = MaxPooling2D(pool_size=(2, 2))(cnn2)
fullyConected = Dense(32)(Reshape(target_shape=(int(cnn2.get_shape()[1]), int(cnn2.get_shape()[2] * cnn2.get_shape()[3])))(cnn2))
fullyConected = BatchNormalization()(fullyConected)
fullyConected = Activation('relu')(fullyConected)
gru = GRU(256, return_sequences=True)(fullyConected)
gru_ = GRU(256, return_sequences=True)(gru)
gru_concat = concatenate([gru, gru_])
dropout = Dropout(0.25)(gru2_merged)
y_pred = Dense(len(char)+1, kernel_initializer='he_normal', activation='softmax')(dropout)


model = Model(inputs=x, outputs=y_pred)
model.compile(loss='categorical_crossentropy', optimizer='sgd',metrics=['accuracy'])
x_train,y_train = getData("train_label.txt")
model.fit(x=x_train, y=y_train, batch_size=32, epochs=100)
model.save("model.h5")

