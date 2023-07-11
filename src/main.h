

#ifndef main_h
#define main_h



typedef struct{
    int mode;
}setup_t;

typedef struct{
    float roll;
    float pitch;
    float yaw;
}t_sensorFusionData;

typedef struct{
    float accX;
    float accY;
    float accZ;
}t_filteredAccData;

struct s_RawSensorData
{
    float gyroX;
    float gyroY;
    float gyroZ;
    float accX;
    float accY;
    float accZ; 
    float magX;
    float magY;
    float magZ;
    float temp;
};

typedef s_RawSensorData t_RawSensorData;


#endif //main_h