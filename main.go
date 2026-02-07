package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"sync"
	"time"
)

// Hold the version number and the version number as a string
var VERSION int = 1
var VERSION_STRING string = strconv.Itoa(VERSION)

var BuildDate string = "-development"

// The struct that holds the JSON values
type Tasks struct {
	Name        string `json:"name"`
	Interpreter string `json:"interpreter"`
	Path        string `json:"path"`
	Time        string `json:"time"`
}

/*
This function parses the time key to work out how often a task should be
run. This splits the time into its two components: the count and the
time character (ie. the s, m, or h). This then converts the count to
the seconds equivalent.
*/
func ParseTime(time string) (int, error) {
	/*
		Get the last character to get the time scale (ie. seconds, minutes or
		hours). This should be one of s, m, or h as a result which is checked
		below.
	*/
	time_scale := string(time[len(time)-1])
	// Get everything up to and including the last character to get the time
	time_length, time_length_error := strconv.Atoi(time[0 : len(time)-1])
	// Throw an error if the length is not a valid integer
	if time_length_error != nil {
		return 0, fmt.Errorf(
			"the time provided is not a valid integer: %s", time,
		)
	}
	/*
		Hold the "multiplier", the value used to convert the time scale
		provided into seconds as seconds are the "base" time scale.
	*/
	var multiplier int

	// Convert the time scale to seconds by setting the multiplier
	switch time_scale {
	/*
		If we're running hours, we need to convert the value to seconds by
		multiplying it by 60^2.
	*/
	case "h":
		multiplier = 60 * 60
	/*
		If we're running minutes, we need to convert the value to seconds by
		multiplying it by 60.
	*/
	case "m":
		multiplier = 60
	/*
		If we're running second, we don't need to convert the value to seconds
		and so we don't need to multiply anything so we set the multiplier to
		one.
	*/
	case "s":
		multiplier = 1
	/*
		If it's not oen of h, m, or s, we've hit an error so we throw one and
		return one alongside a value of zero as a stand in for nothing.
	*/
	default:
		return 0, fmt.Errorf(
			"the last character needs to be one of h, m, or s: %s", time,
		)
	}
	/*
		Convert the time_length to the appropriate value in seconds by using
		the recently set multiplier.
	*/
	time_length = time_length * multiplier
	// Return the time length and nil as an error
	return time_length, nil
}

/*
This function is the actual runner of tasks that is called as a goroutine.
It takes in five parameters:
  - timer: the length of time that is used as the timer for how often a
    task is called.
  - name: the name of the task which is used for logging.
  - interprter: the path to the interpreter used to execute the Appetit
    script.
  - path: the path to the Appetit script.
  - nostdoutlog: a boolean that sets out whether each execution of the
    script should be logged out.
*/
func Runner(
	timer int,
	name string,
	interpreter string,
	path string,
	nostdoutlog bool) {

	/*
		Run an infinite loop on the premise that a SIGINT is the end of the
		script.
	*/
	for {
		// Start our sleeping for the execution of the script
		time.Sleep(time.Duration(timer) * time.Second)
		// Format the date according to the format dd/mm/yyyy hh:mm:ss
		time_now := time.Now().Format("02/01/2006 15:04:05")

		// If nostdoutlog is false, log out when a task is executed
		if !nostdoutlog {
			fmt.Printf(
				"\033[36m[%s]\033[0m Running %s -> %s %s\n",
				time_now,
				name,
				interpreter,
				path,
			)
		}

		/*
			Set the command to be executed by combining the interpreter and the
			path to the script. We still need these seperate so that we can
			send these as parameters to the exec.Command() function.
		*/
		command := interpreter + " " + path
		// Execute the command
		cmd, cmd_err := exec.Command(interpreter, path).Output()
		// If there is an error, report it out.
		if cmd_err != nil {
			fmt.Println("There was an error executing " + command)
		}
		// Output the results of the command
		fmt.Println(string(cmd))

		// Create a logger by opening or creating the log file
		logger, logger_error := os.OpenFile(
			"aptsched.log",
			os.O_APPEND|os.O_CREATE|os.O_WRONLY,
			0644,
		)
		// If there was an error, note it
		if logger_error != nil {
			fmt.Println("\t\033[31m!! Error opening the log\033[0m")
		}
		// Craft the line to add to the log
		log_line := fmt.Sprintf(
			"[%s] Running %s -> %s %s\n",
			time_now,
			name,
			interpreter,
			path,
		)
		// Write the line to the log file
		_, write_error := logger.WriteString(log_line)
		// Throw an error if the writing doesn't work
		if write_error != nil {
			fmt.Println("\t\033[31m!! Error writing the logfile\033[0m")
		}
		/*
			Close the log. This can't be deferred above because this is an
			infinite loop.
		*/
		logger.Close()
	}
}

func main() {

	// Allow the user to execute system commands, defaults to false
	nostdout_flag := flag.Bool(
		"nostdout",
		false,
		"Disable logging to standard out",
	)

	// Version info
	version_flag := flag.Bool(
		"version",
		false,
		"Get version information",
	)
	// Parse the flags
	flag.Parse()

	// If the version flag is present, print out the version and exit
	if *version_flag {
		fmt.Println("Appetit Scheduler (aptsched) v" + VERSION_STRING)
		fmt.Printf("Build Date: %s\n", BuildDate)
		os.Exit(0)
	}

	// Create a WaitGroup. Thanks to https://stackoverflow.com/a/18207832
	var wg sync.WaitGroup
	// Open up the file
	schedule_file, schedule_error := os.ReadFile("aptsched.json")
	// Check to see if there is an error opening up the file
	if schedule_error != nil {
		fmt.Println(schedule_error.Error())
	}

	// Hold our tasks
	var tasks []Tasks

	// Parse the JSON
	parse_error := json.Unmarshal(schedule_file, &tasks)
	// If there's a parsing error, report it
	if parse_error != nil {
		fmt.Println(
			"Error parsing the task file. Check to make sure that it " +
				"follows the proper format.",
		)
	}

	// If the nostdout flag isn't passed, log out intro info to stdout.
	if !*nostdout_flag {
		// Start by printing the
		fmt.Printf(
			"\033[32m:: Appetit Scheduler version %s::\033[0m\n",
			VERSION_STRING,
		)
		/*
			For each task, print out the info to help users see what tasks are
			scheduled. This is a chance to catch any errors that aren't
			technical.
		*/
		for _, detail := range tasks {
			fmt.Println("\033[35m" + detail.Name + "\033[0m")
			fmt.Println("\t\033[33mInterpreter: \033[0m" + detail.Interpreter)
			fmt.Println("\t\033[33mPath: \033[0m" + detail.Path)
			fmt.Println("\t\033[33mTime: \033[0m" + detail.Time)
		}

		// Print out the log header and the start time for logging
		fmt.Println("\n\033[32m:: Log ::\033[0m")
		fmt.Println(
			"Start Time: " + time.Now().Format("02/01/2006 15:04:05"),
		)
	}

	// Iterate over the tasks
	for _, task := range tasks {
		// Add to the WaitGroup
		wg.Add(1)
		// Set some variables to hold the values of the struct
		name := task.Name
		interpreter := task.Interpreter
		path := task.Path
		// Parse the time as returned from the ParseTime() function
		time_value, time_error := ParseTime(task.Time)
		// If there was an error, report it
		if time_error != nil {
			fmt.Println(time_error.Error())
		}
		// Set off the runner as a goroutine
		go Runner(time_value, name, interpreter, path, *nostdout_flag)
	}
	// Wait the WaitGroup
	wg.Wait()
}
