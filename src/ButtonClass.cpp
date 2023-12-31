#include "ButtonClass.h" 
#include <math.h>
#include "Arduino.h"

ButtonClass::ButtonClass(uint8_t pin, bool isTouch)
{
    this->isTouch = isTouch;
    buttonID = pin;
}

mode_button_e ButtonClass::check_button(void)
{
    static bool buttonPressed = false;
    static unsigned long button_time = 0;

    if (isTouch == false)
    {
        //New Button Press
        if ((LOW == digitalRead(buttonID)) && (buttonPressed == false))
        {
            buttonPressed = true;
            button_time = millis();     
            return DOWN; 
        }
        else if ((HIGH == digitalRead(buttonID)) && (buttonPressed == true))
        {
            buttonPressed = false;

            if ((millis() - button_time) > very_very_long_press_ms)
            {        
                return VERY_VERY_LONG_PRESS;
            }        
            else if ((millis() - button_time) > very_long_press_ms)
            {        
                return VERY_LONG_PRESS;
            }
            else if ((millis() - button_time) > long_press_ms)
            {         
                return LONG_PRESS;
            }
        else 
            {            
                return SHORT_PRESS;
            }
        }
        return NO_PRESS;
    }
    else
    {
        //New Button Press
        if ((touch_th > touchRead(buttonID)) && (buttonPressed == false))
        {
            buttonPressed = true;
            button_time = millis();     
            return DOWN; 
        }
        else if ((touchRead(buttonID) > touch_th) && (buttonPressed == true))
        {
            buttonPressed = false;

            if ((millis() - button_time) > very_very_long_press_ms)
            {        
                return VERY_VERY_LONG_PRESS;
            }        
            else if ((millis() - button_time) > very_long_press_ms)
            {        
                return VERY_LONG_PRESS;
            }
            else if ((millis() - button_time) > long_press_ms)
            {         
                return LONG_PRESS;
            }
        else 
            {            
                return SHORT_PRESS;
            }
        }
        return NO_PRESS;
    }
}

void ButtonClass::setTiming(uint16_t long_press_ms,uint16_t very_long_press_ms,uint16_t very_very_long_press_ms)
{
    this->long_press_ms = long_press_ms;
    this->very_long_press_ms = very_long_press_ms;
    this->very_very_long_press_ms = very_very_long_press_ms;
}

void ButtonClass::setTouchThreshold(uint16_t touch_th)
{
    this->touch_th = touch_th;
}