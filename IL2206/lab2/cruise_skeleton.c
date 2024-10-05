/* Cruise control skeleton for the IL 2206 embedded lab
 *
 * Maintainers:  Rodolfo Jordao (jordao@kth.se), George Ungereanu (ugeorge@kth.se)
 *
 * Description:
 *
 *   In this file you will find the "model" for the vehicle that is being simulated on top
 *   of the RTOS and also the stub for the control task that should ideally control its
 *   velocity whenever a cruise mode is activated.
 *
 *   The missing functions and implementations in this file are left as such for
 *   the students of the IL2206 course. The goal is that they get familiriazed with
 *   the real time concepts necessary for all implemented herein and also with Sw/Hw
 *   interactions that includes HAL calls and IO interactions.
 *
 *   If the prints prove themselves too heavy for the final code, they can
 *   be exchanged for alt_printf where hexadecimals are supported and also
 *   quite readable. This modification is easily motivated and accepted by the course
 *   staff.
 */
#include <stdio.h>
#include "os_cpu.h"
#include "system.h"
#include "includes.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"
#include "sys/alt_alarm.h"
#include "ucos_ii.h"

#define DEBUG 1

#define HW_TIMER_PERIOD 100 /* 100ms */

/* Button Patterns */

#define GAS_PEDAL_FLAG      0x08
#define BRAKE_PEDAL_FLAG    0x04
#define CRUISE_CONTROL_FLAG 0x02
/* Switch Patterns */

#define TOP_GEAR_FLAG       0x00000002
#define ENGINE_FLAG         0x00000001

/* LED Patterns */

#define LED_RED_0 0x00000001 // Engine
#define LED_RED_1 0x00000002 // Top Gear

#define LED_GREEN_0 0x0001 // Cruise Control activated
#define LED_GREEN_2 0x0002 // Cruise Control Button
#define LED_GREEN_4 0x0010 // Brake Pedal
#define LED_GREEN_6 0x0040 // Gas Pedal

/*
 * Definition of Tasks
 */

#define TASK_STACKSIZE 2048

OS_STK StartTask_Stack[TASK_STACKSIZE]; 
OS_STK ControlTask_Stack[TASK_STACKSIZE]; 
OS_STK VehicleTask_Stack[TASK_STACKSIZE];
OS_STK ButtonIO_Stack[TASK_STACKSIZE];
OS_STK SwitchIO_Stack[TASK_STACKSIZE];
OS_STK Helper_Stack[TASK_STACKSIZE];
OS_STK Watchdog_Stack[TASK_STACKSIZE];
OS_STK Extraload_Stack[TASK_STACKSIZE];

// Task Priorities

#define STARTTASK_PRIO     5
#define VEHICLETASK_PRIO   10
#define CONTROLTASK_PRIO   12
#define BUTTON_PRIO        6
#define SWITCH_PRIO        7
#define HELPER_PRIO        3
#define WATCHDOG_PRIO      1
#define EXTRALOAD_PRIO     2


// Task Periods

#define CONTROL_PERIOD   300
#define VEHICLE_PERIOD   300
#define BUTTON_PERIOD    300
#define SWITCH_PERIOD    300
#define WATCHDOG_PERIOD  300
#define HELPER_PERIOD    300
#define EXTRALOAD_PERIOD 300
/*
 * Definition of Kernel Objects 
 */

// Mailboxes
OS_EVENT *Mbox_Throttle;
OS_EVENT *Mbox_Velocity;
OS_EVENT *Mbox_Brake;
OS_EVENT *Mbox_Engine;
OS_EVENT *Mbox_Gear;
OS_EVENT *Mbox_Cruise;
OS_EVENT *Mbox_Gas;

// Semaphores

OS_EVENT *Sem_Vehicle;
OS_EVENT *Sem_Control;
OS_EVENT *Sem_Switch;
OS_EVENT *Sem_Button;
OS_EVENT *Sem_Helper;
OS_EVENT *Sem_Watchdog;
OS_EVENT *Sem_Extraload;
OS_EVENT *Sem_OK;

// SW-Timer

OS_TMR *Tmr_Vehicle;
OS_TMR *Tmr_Control;
OS_TMR *Tmr_Switch;
OS_TMR *Tmr_Button;
OS_TMR *Tmr_Helper;
OS_TMR *Tmr_Watchdog;
OS_TMR *Tmr_ExtraLoad;

/*
 * Types
 */

enum active {on = 2, off = 1};

/*
 * Global variables
 */
int delay; // Delay of HW-timer 
INT16U led_green = 0; // Green LEDs
INT32U led_red = 0;   // Red LEDs

/*
 * Helper functions
 */

int buttons_pressed(void)
{
  return ~IORD_ALTERA_AVALON_PIO_DATA(D2_PIO_KEYS4_BASE);    
}

int switches_pressed(void)
{
  return IORD_ALTERA_AVALON_PIO_DATA(DE2_PIO_TOGGLES18_BASE);    
}

// Callback for SW Timer
void vehicleCallback(void){
  OSSemPost(Sem_Vehicle);
}

void controlCallback(void){
  OSSemPost(Sem_Control);
}

void switchCallback(void){
  OSSemPost(Sem_Switch);
}

void buttonCallback(void) {
  OSSemPost(Sem_Button);
}

void helperCallback(void) {
  OSSemPost(Sem_Helper);
}

void watchdogCallback(void) {
  OSSemPost(Sem_Watchdog);
}

void extraloadCallback(void) {
  OSSemPost(Sem_Extraload);
}


/*
 * ISR for HW Timer
 */
alt_u32 alarm_handler(void* context)
{
  OSTmrSignal(); /* Signals a 'tick' to the SW timers */

  return delay;
}

static int b2sLUT[] = {0x40, //0
  0x79, //1
  0x24, //2
  0x30, //3
  0x19, //4
  0x12, //5
  0x02, //6
  0x78, //7
  0x00, //8
  0x18, //9
  0x3F, //-
};

/*
 * convert int to seven segment display format
 */
int int2seven(int inval){
  return b2sLUT[inval];
}

/*
 * output current velocity on the seven segement display
 */
void show_velocity_on_sevenseg(INT8S velocity){
  int tmp = velocity;
  int out;
  INT8U out_high = 0;
  INT8U out_low = 0;
  INT8U out_sign = 0;

  if(velocity < 0){
    out_sign = int2seven(10);
    tmp *= -1;
  }else{
    out_sign = int2seven(0);
  }

  out_high = int2seven(tmp / 10);
  out_low = int2seven(tmp - (tmp/10) * 10);

  out = int2seven(0) << 21 |
    out_sign << 14 |
    out_high << 7  |
    out_low;
  IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_HEX_LOW28_BASE,out);
}

/*
 * shows the target velocity on the seven segment display (HEX5, HEX4)
 * when the cruise control is activated (0 otherwise)
 */
void show_target_velocity(INT8U target_vel)
{
  int tmp = target_vel;
  int out;
  INT8U out_high = 0;
  INT8U out_low = 0;
  INT8U out_sign = 0;

  if(target_vel < 0){
    out_sign = int2seven(10);
    tmp *= -1;
  }else{
    out_sign = int2seven(0);
  }

  out_high = int2seven(tmp / 10);
  out_low = int2seven(tmp - (tmp/10) * 10);

  out = int2seven(0) << 21 |
    out_sign << 14 |
    out_high << 7  |
    out_low;
  IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_HEX_HIGH28_BASE,out); 
}

/*
 * indicates the position of the vehicle on the track with the four leftmost red LEDs
 * LEDR17: [0m, 400m)
 * LEDR16: [400m, 800m)
 * LEDR15: [800m, 1200m)
 * LEDR14: [1200m, 1600m)
 * LEDR13: [1600m, 2000m)
 * LEDR12: [2000m, 2400m]
 */
void show_position(INT16U position)
{
  INT32U mask = 0x0003f000;
  INT32U led_r17 = 0x00020000;
  led_red = IORD_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE);
  IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE, led_red  & ~mask | (led_r17 >> (position / 400)));
}

void cruise_off() {
  led_green = IORD_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE);
  int is_cruise_on = led_green & LED_GREEN_2;
  if(is_cruise_on) {
    printf("off\n");
    OSMboxPost(Mbox_Cruise, (void *)off);
    IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE, led_green & (~LED_GREEN_2));
  }
}

void SwitchIO(void *arg){
  INT8U err;
  printf("SwitchIO created!\n");

  while(1) {
      int sw0_status = switches_pressed() & ENGINE_FLAG;
      int sw1_status = switches_pressed() & TOP_GEAR_FLAG;
      int led_red = IORD_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE);
      if(sw0_status) {
          OSMboxPost(Mbox_Engine, (void *) on);
          IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE, led_red | LED_RED_0);
      } else {
          INT16S *velocity = OSMboxPend(Mbox_Velocity, 1, &err);
          if((err == OS_ERR_NONE) && (*velocity == 0)) {
              OSMboxPost(Mbox_Engine, (void *) off);
              IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE, led_red & (~LED_RED_0));
          }
      }
      
      led_red = IORD_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE);
      if(sw1_status) {
          OSMboxPost(Mbox_Gear, (void *) on);
          IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE, led_red | LED_RED_1);
      } else {
          OSMboxPost(Mbox_Gear, (void *) off);
          IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE, led_red & (~LED_RED_1));
          cruise_off();
      }

      OSSemPend(Sem_Switch, 0, &err);
  }
  
}

void ButtonIO(void *arg){
  INT8U err;
  int buttons = 0;
  printf("create ButtonIO task!");
  while(1) {
    //printf("*******************");
    OSSemPend(Sem_Button, 0, &err);//  
  

    buttons = buttons_pressed();
    int bt1_status = buttons & CRUISE_CONTROL_FLAG;
    int bt2_status = buttons & BRAKE_PEDAL_FLAG;
    int bt3_status = buttons & GAS_PEDAL_FLAG;
    
    led_red = IORD_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE);
    led_green = IORD_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE);

    // curise button

    INT16S *velocity;
    if(bt1_status) {
      int is_cruise_on = led_green & LED_GREEN_2;
      int is_gear_high = led_red & LED_RED_1; 
      int is_brake_on = led_green & LED_GREEN_4;
      int is_gas_on = led_green & LED_GREEN_6;
      void* msg = OSMboxPend(Mbox_Velocity, 1, &err);
      if(err == OS_NO_ERR) {
        velocity = ((INT16S *) msg);
        if(is_cruise_on){
          cruise_off();
        } else if((*velocity >= 20) && is_gear_high && !is_gas_on && !is_brake_on) {
          OSMboxPost(Mbox_Cruise, (void *)on);
          IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE, led_green | (LED_GREEN_2));
        }
      }
      do {
        buttons = buttons_pressed();
        bt1_status = buttons & CRUISE_CONTROL_FLAG;
      } while(bt1_status);
    }

    // brake button
    led_green = IORD_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE);
    if(bt2_status) {
      OSMboxPost(Mbox_Brake, (void *)on);
      IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE, led_green | (LED_GREEN_4));
      cruise_off();
    } else {
      OSMboxPost(Mbox_Brake, (void *)off);
      IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE, led_green & (~LED_GREEN_4));
    }

    // gas button
    led_green = IORD_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE);
    if(bt3_status) {
      OSMboxPost(Mbox_Gas, (void *)on);
      IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE, led_green | (LED_GREEN_6));
      cruise_off();
    } 
    else {
      OSMboxPost(Mbox_Gas, (void *)off);
      IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE, led_green & (~LED_GREEN_6));
    }
  }


}


/*
 * The task 'VehicleTask' is the model of the vehicle being simulated. It updates variables like
 * acceleration and velocity based on the input given to the model.
 * 
 * The car model is equivalent to moving mass with linear resistances acting upon it.
 * Therefore, if left one, it will stably stop as the velocity converges to zero on a flat surface.
 * You can prove that easily via basic LTI systems methods.
 */
void VehicleTask(void* pdata)
{ 
  // constants that should not be modified
  const unsigned int wind_factor = 1;
  const unsigned int brake_factor = 4;
  const unsigned int gravity_factor = 2;
  // variables relevant to the model and its simulation on top of the RTOS
  INT8U err;   
  void* msg;
  INT8U* throttle; 
  INT16S acceleration;  
  INT16U position = 0; 
  INT16S velocity = 0; 
  enum active brake_pedal = off;
  enum active engine = off;
  printf("Vehicle task created!\n");

  while(1)
  {
    err = OSMboxPost(Mbox_Velocity, (void *) &velocity);

    // OSTimeDlyHMSM(0,0,0,VEHICLE_PERIOD); 

    /* Non-blocking read of mailbox: 
       - message in mailbox: update throttle
       - no message:         use old throttle
       */
    msg = OSMboxPend(Mbox_Throttle, 1, &err); 
    if (err == OS_NO_ERR) 
      throttle = (INT8U*) msg;
    /* Same for the brake signal that bypass the control law */
    msg = OSMboxPend(Mbox_Brake, 1, &err); 
    if (err == OS_NO_ERR) 
      brake_pedal = (enum active) msg;
    /* Same for the engine signal that bypass the control law */
    msg = OSMboxPend(Mbox_Engine, 1, &err); 
    if (err == OS_NO_ERR) 
      engine = (enum active) msg;


    // vehichle cannot effort more than 80 units of throttle
    if (*throttle > 80) *throttle = 80;

    // brakes + wind
    if (brake_pedal == off)
    {
      // wind resistance
      acceleration = - wind_factor*velocity;
      // actuate with engines
      if (engine == on)
        acceleration += (*throttle);

      // gravity effects
      if (400 <= position && position < 800)
        acceleration -= gravity_factor; // traveling uphill
      else if (800 <= position && position < 1200)
        acceleration -= 2*gravity_factor; // traveling steep uphill
      else if (1600 <= position && position < 2000)
        acceleration += 2*gravity_factor; //traveling downhill
      else if (2000 <= position)
        acceleration += gravity_factor; // traveling steep downhill
    }
    // if the engine and the brakes are activated at the same time,
    // we assume that the brake dynamics dominates, so both cases fall
    // here.
    else 
      acceleration = - brake_factor*velocity;

    printf("Position: %d m\n", position);
    printf("Velocity: %d m/s\n", velocity);
    printf("Accell: %d m/s2\n", acceleration);
    printf("Throttle: %d V\n", *throttle);

    position = position + velocity * VEHICLE_PERIOD / 1000;
    velocity = velocity  + acceleration * VEHICLE_PERIOD / 1000.0;
    // reset the position to the beginning of the track
    if(position >= 2400)
      position = 0;

    show_velocity_on_sevenseg((INT8S) velocity);
    show_position(position);

    OSSemPend(Sem_Vehicle, 0, &err);
  }
} 

/*
 * The task 'ControlTask' is the main task of the application. It reacts
 * on sensors and generates responses.
 */

void ControlTask(void* pdata)
{
  INT8U err;
  INT8U throttle = 40; /* Value between 0 and 80, which is interpreted as between 0.0V and 8.0V */
  void* msg;
  INT16S* current_velocity, target_veloxity = 0;

  enum active gas_pedal = off;
  enum active top_gear = off;
  enum active cruise_control = off; 

  printf("Control Task created!\n");

  msg = OSMboxPend(Mbox_Velocity, 0, &err);
  current_velocity = (INT16S*) msg;

  while(1)
  {
    msg = OSMboxPend(Mbox_Cruise, 1, &err);
    if(err == OS_ERR_NONE) {
      cruise_control = (enum active) msg; 
      if(cruise_control == on) {
        target_veloxity = *current_velocity;
      } else {
        target_veloxity = 0;
      }
    }
    show_target_velocity(target_veloxity);

    msg = OSMboxPend(Mbox_Gas, 1, &err);
    if(err == OS_ERR_NONE) {
      gas_pedal = (enum active) msg;
    }

    msg = OSMboxPend(Mbox_Gear, 1, &err);
    if(err == OS_ERR_NONE) {
      top_gear = (enum active) msg;
    }

    // Cruise mode
    float kp = 3.8, ki = 2.0;
    INT16S pre_diff, diff = 0;
    pre_diff = diff;
    diff = target_veloxity - *current_velocity;
    if(cruise_control == on) {
      if(*current_velocity <= 20){
        cruise_off();
      }
      else if(diff < -5) {
        throttle = throttle - 5;
      } else if(diff > 5) {
        throttle = kp * diff + ki * (pre_diff + diff);
      }
    } else if(gas_pedal == on) {
        throttle = 80;
    } else {
        throttle = 0;
    }

    // Here you can use whatever technique or algorithm that you prefer to control
    // the velocity via the throttle. There are no right and wrong answer to this controller, so
    // be free to use anything that is able to maintain the cruise working properly. You are also
    // allowed to store more than one sample of the velocity. For instance, you could define
    //
    // INT16S previous_vel;
    // INT16S pre_previous_vel;
    // ...
    //
    // If your control algorithm/technique needs them in order to function. 

    err = OSMboxPost(Mbox_Throttle, (void *) &throttle);

    // OSTimeDlyHMSM(0,0,0, CONTROL_PERIOD);
    OSSemPend(Sem_Control, 0, &err);
  }
}

void Helper(void* pdata) {
  INT8U err;
  while(1) {
    OSSemPend(Sem_Helper, 0, &err);
    OSSemPost(Sem_OK);
  }
}

void Watchdog(void* pdata) {
  INT8U err;
  while(1) {
    OSSemPend(Sem_Watchdog, 0, &err);
    OSSemPend(Sem_OK, 290, &err);

    if(err != OS_NO_ERR) {
      printf("overload detected!!!\n");
    }
  }
}

void Extraload(void* pdata) {
  INT8U err;
  while(1) {
    OSSemPend(Sem_Extraload, 0, &err);
    int utilization = get_utilization();
    printf("utilization:%d\n", utilization);
    // OSTimeDlyHMSM(0,0,0, utilization / 100 * 300); 
    int i = 0, j = 0, x = 0;
    // PERF_START_MEASURING(PERFORMANCE_COUNTER_BASE);
    for(i=0;i<1000;i++)
      for(j=0;j<utilization;j++) {
        x = x+1;
      }
    // PERF_STOP_MEASURING(PERFORMANCE_COUNTER_BASE);
    // alt_u64 measure_time = perf_get_total_time(PERFORMANCE_COUNTER_BASE);
    // PERF_RESET(PERFORMANCE_COUNTER_BASE);
    // int frequency = alt_ticks_per_second();
    // int real_time = measure_time / frequency * 1000;
    //printf("%d seconds\n", real_time);
  }
}

int get_utilization() {
  int flag = 0;
  int i;
  for(i = 4; i <=9; i++) {
    if(switches_pressed() & (1 << i)) {
      flag |= (1 << i);
    }
  }
  INT32U mask = 0x000003f0; 
  int led_red = IORD_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE);
  // set redled lights using mask :)
  IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE, led_red & ~mask | flag);
  int utilization = (flag >> 4) * 2;
  if(utilization < 100) {
    return utilization;
  } else {
    return 100;
  }
}

/* 
 * The task 'StartTask' creates all other tasks kernel objects and
 * deletes itself afterwards.
 */ 

void StartTask(void* pdata)
{
  INT8U err, tmr_err;
  void* context;

  static alt_alarm alarm;     /* Is needed for timer ISR function */

  /* Base resolution for SW timer : HW_TIMER_PERIOD ms */
  delay = alt_ticks_per_second() * HW_TIMER_PERIOD / 1000; 
  printf("delay in ticks %d\n", delay);

  /* 
   * Create Hardware Timer with a period of 'delay' 
   */
  if (alt_alarm_start (&alarm,
        delay,
        alarm_handler,
        context) < 0)
  {
    printf("No system clock available!n");
  }

  // Create Semaphores
  Sem_Vehicle = OSSemCreate(0);
  Sem_Control = OSSemCreate(0);
  Sem_Switch  = OSSemCreate(0);
  Sem_Button = OSSemCreate(0);
  Sem_Helper = OSSemCreate(0);
  Sem_Watchdog = OSSemCreate(0);
  Sem_Extraload = OSSemCreate(0);
  Sem_OK = OSSemCreate(0);

  /* 
   * Create and start Software Timer 
   */

  Tmr_Vehicle = OSTmrCreate(0, 
                            VEHICLE_PERIOD * 0.001 * OS_TMR_CFG_TICKS_PER_SEC, 
                            OS_TMR_OPT_PERIODIC, 
                            vehicleCallback, 
                            NULL, 
                            "vehicle_period_timer", 
                            &tmr_err);

  Tmr_Control = OSTmrCreate(0, 
                            CONTROL_PERIOD * 0.001 * OS_TMR_CFG_TICKS_PER_SEC, 
                            OS_TMR_OPT_PERIODIC, 
                            controlCallback, 
                            NULL, 
                            "control_period_timer", 
                            &tmr_err);
                          
  Tmr_Switch  = OSTmrCreate(0, 
                            SWITCH_PERIOD * 0.001 * OS_TMR_CFG_TICKS_PER_SEC, 
                            OS_TMR_OPT_PERIODIC, 
                            switchCallback, 
                            NULL, 
                            "switch_period_timer", 
                            &tmr_err);

  Tmr_Button = OSTmrCreate(0, 
                          BUTTON_PERIOD * 0.001 * OS_TMR_CFG_TICKS_PER_SEC,
                          OS_TMR_OPT_PERIODIC,
                          buttonCallback,
                          NULL,
                          "button_period_timer",
                          &tmr_err);

  Tmr_Helper = OSTmrCreate(0,
                            HELPER_PERIOD * 0.001 * OS_TMR_CFG_TICKS_PER_SEC,
                            OS_TMR_OPT_PERIODIC,
                            helperCallback,
                            NULL,
                            "helper_timer",
                            &tmr_err);

  Tmr_Watchdog = OSTmrCreate(0,
                            WATCHDOG_PERIOD * 0.001 * OS_TMR_CFG_TICKS_PER_SEC,
                            OS_TMR_OPT_PERIODIC,
                            watchdogCallback,
                            NULL,
                            "watchdog_timer",
                            &tmr_err);

  Tmr_ExtraLoad = OSTmrCreate(0,
                              EXTRALOAD_PERIOD * 0.001 * OS_TMR_CFG_TICKS_PER_SEC,
                              OS_TMR_OPT_PERIODIC,
                              extraloadCallback,
                              NULL,
                              "extraload_timer",
                              &tmr_err);

  
  OSTmrStart(Tmr_Vehicle, &err);
  OSTmrStart(Tmr_Control, &err);
  OSTmrStart(Tmr_Switch, &err);
  OSTmrStart(Tmr_Button, &err);
  OSTmrStart(Tmr_Helper, &err);
  OSTmrStart(Tmr_Watchdog, &err);
  OSTmrStart(Tmr_ExtraLoad, &err);
  /*
   * Creation of Kernel Objects
   */

  // Mailboxes
  Mbox_Throttle = OSMboxCreate((void*) 0); /* Empty Mailbox - Throttle */
  Mbox_Velocity = OSMboxCreate((void*) 0); /* Empty Mailbox - Velocity */
  Mbox_Brake = OSMboxCreate((void*) off); /* Empty Mailbox - Velocity */
  Mbox_Engine = OSMboxCreate((void*) off); /* Empty Mailbox - Engine */
  Mbox_Gear = OSMboxCreate((void*) off);
  Mbox_Cruise = OSMboxCreate((void*) off);
  Mbox_Gas = OSMboxCreate((void*) off);

  /*
   * Create statistics task
   */

  OSStatInit();

  /* 
   * Creating Tasks in the system 
   */


  err = OSTaskCreateExt(
        ControlTask, // Pointer to task code
        NULL,        // Pointer to argument that is
        // passed to task
        &ControlTask_Stack[TASK_STACKSIZE-1], // Pointer to top
        // of task stack
        CONTROLTASK_PRIO,
        CONTROLTASK_PRIO,
        (void *)&ControlTask_Stack[0],
        TASK_STACKSIZE,
        (void *) 0,
        OS_TASK_OPT_STK_CHK
      );

  err = OSTaskCreateExt(
        VehicleTask, // Pointer to task code
        NULL,        // Pointer to argument that is
        // passed to task
        &VehicleTask_Stack[TASK_STACKSIZE-1], // Pointer to top
        // of task stack
        VEHICLETASK_PRIO,
        VEHICLETASK_PRIO,
        (void *)&VehicleTask_Stack[0],
        TASK_STACKSIZE,
        (void *) 0,
        OS_TASK_OPT_STK_CHK
      );

    err = OSTaskCreateExt(
        SwitchIO, // Pointer to task code
        NULL,     // Pointer to argument that is
        // passed to task
        &SwitchIO_Stack[TASK_STACKSIZE-1], // Pointer to top
        // of task stack
        SWITCH_PRIO,
        SWITCH_PRIO,
        (void *)&SwitchIO_Stack[0],
        TASK_STACKSIZE,
        (void *) 0,
        OS_TASK_OPT_STK_CHK
      );

    err = OSTaskCreateExt(
        ButtonIO,
        NULL,
        &ButtonIO_Stack[TASK_STACKSIZE-1],
        BUTTON_PRIO,
        BUTTON_PRIO,
        (void *)&ButtonIO_Stack[0],
        TASK_STACKSIZE,
        (void *) 0,
        OS_TASK_OPT_STK_CHK
      );
    
    err = OSTaskCreateExt(
        Helper,
        NULL,
        &Helper_Stack[TASK_STACKSIZE-1],
        HELPER_PRIO,
        HELPER_PRIO,
        (void *)&Helper_Stack[0],
        TASK_STACKSIZE,
        (void *) 0,
        OS_TASK_OPT_STK_CHK
    );

    err  = OSTaskCreateExt(
         Watchdog,
         NULL,
         &Watchdog_Stack[TASK_STACKSIZE-1],
         WATCHDOG_PRIO,
         WATCHDOG_PRIO,
         (void *)&Watchdog_Stack[0],
         TASK_STACKSIZE,
         (void *) 0,
         OS_TASK_OPT_STK_CHK
    );

    err = OSTaskCreateExt(
        Extraload,
        NULL,
        &Extraload_Stack[TASK_STACKSIZE-1],
        EXTRALOAD_PRIO,
        EXTRALOAD_PRIO,
        (void *)&Extraload_Stack[0],
        TASK_STACKSIZE,
        (void *) 0,
        OS_TASK_OPT_STK_CHK
    );

  printf("All Tasks and Kernel Objects generated!\n");

  /* Task deletes itself */

  OSTaskDel(OS_PRIO_SELF);
}

/*
 *
 * The function 'main' creates only a single task 'StartTask' and starts
 * the OS. All other tasks are started from the task 'StartTask'.
 *
 */

int main(void) {

  printf("Lab: Cruise Control\n");

  OSTaskCreateExt(
      StartTask, // Pointer to task code
      NULL,      // Pointer to argument that is
      // passed to task
      (void *)&StartTask_Stack[TASK_STACKSIZE-1], // Pointer to top
      // of task stack 
      STARTTASK_PRIO,
      STARTTASK_PRIO,
      (void *)&StartTask_Stack[0],
      TASK_STACKSIZE,
      (void *) 0,  
      OS_TASK_OPT_STK_CHK | OS_TASK_OPT_STK_CLR);

  OSStart();

  return 0;
}
