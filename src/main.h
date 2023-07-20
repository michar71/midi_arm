

#ifndef main_h
#define main_h

typedef struct{
    char magic0;
    char magic1;
    char magic2;
    char magic3;
    char magic4;
    float acc_bias_x;
    float acc_bias_y;
    float acc_bias_z;
    float gyro_bias_x;
    float gyro_bias_y;
    float gyro_bias_z;
    float mag_bias_x;
    float mag_bias_y;
    float mag_bias_z;
    float mag_scale_x;
    float mag_scale_y;
    float mag_scale_z;
}setup_t;


typedef struct{
    float roll;
    float pitch;
    float yaw;
}t_sensorFusionData;




#endif //main_h