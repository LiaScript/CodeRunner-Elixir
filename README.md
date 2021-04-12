<!--
author:   André Dietrich

email:    LiaScript@github.io

version:  0.0.2

language: en

narrator: US English Male

comment:  This template allows to run C, C++, C# code on a server, while
          communication with LiaScript-courses.

script:   https://cdn.jsdelivr.net/npm/phoenix-js@1.0.3/dist/glob/main.js

@LIA.eval: @LIA.eval_(false,@uid,`@0`,@1,@2)
@LIA.evalWithDebug: @LIA.eval_(true,@uid,`@0`,@1,@2)

@LIA.eval_
<script>
var hash = Math.random().toString(36).replace(/[^a-z]+/g, '')
var ROOT_SOCKET = 'wss://liarunner.herokuapp.com/socket'; // default path is /socket

var socket = new Socket(ROOT_SOCKET, { timeout: 30000 });

socket.connect(); // connect
var chan = socket.channel("lia:"+hash);

// eta timer and retry counter for heroku startup
send.lia("LIA: terminal")
send.lia("LIA: stop")

var timer = 105 // seconds (found by testing)
var connected = false
var current_retries = 0

setInterval(() => {
  if(!connected) {
    console.clear();
    if(timer > 0) {
        timer--;
        if(timer < 95) console.log(`ETA until execution: ${timer}s, Retries: ${current_retries}`);
    }
    else if(timer <= 0) {
      console.log(`Couldn't reach server in the estimated time. Is your internet connection working?`)
    }
  }
}, 1000)

// ----

chan.on("service", (e) => {
  if(!connected) {
    connected = true;
    console.clear();
    send.lia("LIA: terminal")
    current_retries = 0
  }

  if (e.message.stderr)
    console.error(e.message.stderr)
  else if (e.message.stdout) {
    if (!e.message.stdout.startsWith("Warning: cannot switch "))
      console.log(e.message.stdout)
  }
  else if (e.message.exit) {
    if(@0) console.debug(e.message.exit)
    send.lia("LIA: stop")
  }
})

// error hook gets called, when a reconnect is attemted
socket.onError((e) => {
  current_retries++
})

var order = @2
var files = {}

if (order[0])
  files[order[0]] = `@input(0)`
if (order[1])
  files[order[1]] = `@input(1)`
if (order[2])
  files[order[2]] = `@input(2)`
if (order[3])
  files[order[3]] = `@input(3)`
if (order[4])
  files[order[4]] = `@input(4)`
if (order[5])
  files[order[5]] = `@input(5)`
if (order[6])
  files[order[6]] = `@input(6)`
if (order[7])
  files[order[7]] = `@input(7)`

if (order[8])
  files[order[8]] = `@input(8)`
if (order[9])
  files[order[9]] = `@input(9)`


chan.join()
.receive("ok", (e) => {
    chan.push("lia", {event_id: "@1", message: {start: "CodeRunner", settings: null}})
    .receive("ok", (e) => {
        chan.push("lia", {event_id: "@1", message: {files: files}})
        .receive("ok", (e) => {
            if(@0) console.debug(e.message)
            chan.push("lia", {event_id: "@1", message: {compile: @3, order: order}})
            .receive("ok", (e) => {
                if(@0) console.debug(e.message)
                chan.push("lia", {event_id: "@1", message: {execute: @4}})
                .receive("ok", (e) => {})
                .receive("error", (e) => {
                    console.err("could not start application => ", e)
                    chan.push("lia", {event_id: "@1", message: {stop: ""}})
                    send.lia("LIA: stop")
                })
            })
            .receive("error", (e) => {
                send.lia(e.message, e.details, false)
                chan.push("lia", {event_id: "@1", message: {stop: ""}})
                send.lia("LIA: stop")
            })
        })
        .receive("error", (e) => {
            lia.error("could not setup files => ", e)
            chan.push("lia", {event_id: "@1", message: {stop: ""}})
            send.lia("LIA: stop")
        })
    })
    .receive("error", (e) => {
        lia.error("could not start service => ", e)
        chan.push("lia", {event_id: "@1", message: {stop: ""}})
        send.lia("LIA: stop")
    })
})
.receive("error", (e) => { lia.error("channel join => ", e); });


send.handle("input", (e) => {
    chan.push("lia", {event_id: "@1", message: {input: e}})
})
send.handle("stop",  (e) => {
    chan.push("lia", {event_id: "@1", message: {stop: ""}})
});


"LIA: wait"
</script>
@end
-->

# CodeRunner

                         --{{0}}--
This project allows you to run a code-running server, based on Elixir, that
can compile and execute code and communicate via websockets. Thus, if you want
to develop some interactive online courses, this is probably a good way to
start. This README is also a self-contained LiaScript template, that defines
some basic macros, which can be used to make your Markdown code-snippets
executable.

__Try it on LiaScript:__

https://liascript.github.io/course/?https://github.com/liascript/CodeRunner

__See the project on Github:__

https://github.com/liascript/CodeRunner

                        --{{1}}--
There are three ways to use this template. The easiest way is to use the
`import` statement and the URL of the raw text-file of the master branch or any
other branch or version. But you can also copy the required functionality
directly into the header of your Markdown document, see therefor the
[last slide](#3). And of course, you could also clone this project and change
it, as you wish.

	                        {{1}}
1. Load the macros via

   `import: https://github.com/liascript/CodeRunner`

2. Copy the definitions into your Project

3. Clone this repository on GitHub



## `@LIA.eval`

You only have to attach the command `@LIA.eval` to your code-block or project
and pass three parameters.

1. The first, is a list of filenames, the number of sequential code-blocks
   defines the naming order.
2. Then pass the command how your code should be compiled
3. And as the last part, how to execute your code.


```` Markdown
```c
#include <stdio.h>

int main (void){
  printf ("Hello, world \n");

	return 0;
}
```
@LIA.eval(`["main.c"]`, `gcc -Wall main.c -o a.out`, `./a.out`)
````

You can currently use python 2 and 3, gcc, g++, avr-g++, arduino-builder, clang,
and javac.

### C


```c
#include <stdio.h>

int main (void){
	int i = 0;
	int max = 0;

	printf("How many hellos: ");
	scanf("%d",&max);

  for(i=0; i<max; i++)
    printf ("Hello, world %d!\n", i);

	return 0;
}
```
@LIA.eval(`["main.c"]`, `gcc -Wall main.c -o a.out`, `./a.out`)


### C++


```c
#include <stdio.h>

int main (void){
	int i = 0;
	int max = 0;

	printf("How many hellos: ");
	scanf("%d",&max);

  for(i=0; i<max; i++)
    printf ("Hello, world %d!\n", i);

	return 0;
}
```
@LIA.eval(`["main.cpp"]`, `g++ main.cpp -o a.out`, `./a.out`)

### C# dotnet


```csharp
using System;
using System.Collections.Generic;
using System.Collections;
using System.Linq;
using System.Text;

int n;
Console.Write("Number of primes: ");
n = int.Parse(Console.ReadLine());

ArrayList primes = new ArrayList();
primes.Add(2);

for(int i = 3; primes.Count < n; i++) {
	bool isPrime = true;
	foreach(int num in primes) isPrime &= i % num != 0;
	if(isPrime) primes.Add(i);
}

Console.Write("Primes: ");
foreach(int prime in primes) Console.Write($" {prime}");
```
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net5.0</TargetFramework>
  </PropertyGroup>
</Project>

```
@LIA.eval(`["Program.cs", "project.csproj"]`, `dotnet build -nologo`, `dotnet run -nologo`)

### C# mono


```csharp
/*
 * C# Program to Check whether the Entered Number is Even or Odd
 */
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace check1
{
    class Program
    {
        static void Main(string[] args)
        {
            int i;
            Console.Write("Enter a Number : ");
            i = int.Parse(Console.ReadLine());
            if (i % 2 == 0)
            {
                Console.Write("Entered Number is an Even Number");
            }
            else
            {
                Console.Write("Entered Number is an Odd Number");
            }
        }
    }
}
```
@LIA.eval(`["main.cs"]`, `mono main.cs`, `mono main.exe`)


### Python2


```python
for i in range(10):
  print "Hallo Welt", i
```
@LIA.eval(`["main.py"]`, `python -m compileall .`, `python main.pyc`)


### Python3


```pythong
for i in range(10):
  print("Hallo Welt", i)
```
@LIA.eval(`["main.py"]`, `python3 -m compileall .`, `python3 main.py`)

## `@LIA.evalWithDebug`

This does basically the same as `@LIA.eval`, but it will add additional
Debug-information about the CodeRunner status to the console.


```c
#include <stdio.h>

int main (void){
	int i = 0;
	int max = 0;

	printf("How many hellos: ");
	scanf("%d",&max);

  for(i=0; i<max; i++)
    printf ("Hello, world %d!\n", i);

	return 0;
}
```
@LIA.evalWithDebug(`["main.c"]`, `gcc -Wall main.c -o a.out`, `./a.out`)


## Deploying to Heroku

If you deploy this to heroku, as we do, keep in mind, that the __free__ service
will be shut down, if no one uses it for 30 minutes, it takes round about 30
sec. to resurrect.

1. Install the [Heroku-CLI](https://devcenter.heroku.com/articles/heroku-cli)
2. Create a new Heroku project

   1. Login to Heroku: `heroku login` (Don't use sudo or it will not work!)
   2. Create the project: `heroku create [app_name]`

3. Login to Heroku container: `heroku container:login` (It's important
   that you have docker installed before executing this command
   and [make sure that your user is added to the docker group](https://docs.docker.com/engine/install/linux-postinstall/).)
4. Build the docker container and upload it to heroku:
   `heroku container:push web -a app_name`
5. Release the docker container: `heroku container:release web -a app_name`

Your project url is now `app_name.herokuapp.com`. (Or the auto-generated one
when you haven't supplied an app name.)

If you deploy your own server, you have to change the websocket-url in the main
header (main HTML comment of your Markdown document) from
`wss://liarunner.herokuapp.com/socket` to `wss://*******.herokuapp.com/socket` ...
what ever the name of your app is ...


## Implementation


                              --{{0}}--
If you want to minimize loading effort in your LiaScript project, you can also
copy this code and paste it into your main comment header, see the code in the
raw file of this document.

{{1}} https://raw.githubusercontent.com/liaScript/CodeRunner/master/README.md

``` js
script:   https://cdn.jsdelivr.net/npm/phoenix-js@1.0.3/dist/glob/main.js

@LIA.eval: @LIA.eval_(false,@uid,`@0`,@1,@2)
@LIA.evalWithDebug: @LIA.eval_(true,@uid,`@0`,@1,@2)

@LIA.eval_
<script>
var hash = Math.random().toString(36).replace(/[^a-z]+/g, '')
var ROOT_SOCKET = 'wss://liarunner.herokuapp.com/socket'; // default path is /socket

var socket = new Socket(ROOT_SOCKET, { timeout: 30000 });

socket.connect(); // connect
var chan = socket.channel("lia:"+hash);

// eta timer and retry counter for heroku startup
send.lia("LIA: terminal")
send.lia("LIA: stop")

var timer = 105 // seconds (found by testing)
var connected = false
var current_retries = 0

setInterval(() => {
  if(!connected) {
    console.clear();
    if(timer > 0) {
        timer--;
        if(timer < 95) console.log(`ETA until execution: ${timer}s, Retries: ${current_retries}`);
    }
    else if(timer <= 0) {
      console.log(`Couldn't reach server in the estimated time. Is your internet connection working?`)
    }
  }
}, 1000)

// ----

chan.on("service", (e) => {
  if(!connected) {
    connected = true;
    console.clear();
    send.lia("LIA: terminal")
    current_retries = 0
  }

  if (e.message.stderr)
    console.error(e.message.stderr)
  else if (e.message.stdout) {
    if (!e.message.stdout.startsWith("Warning: cannot switch "))
      console.log(e.message.stdout)
  }
  else if (e.message.exit) {
    if(@0) console.debug(e.message.exit)
    send.lia("LIA: stop")
  }
})

// error hook gets called, when a reconnect is attemted
socket.onError((e) => {
  current_retries++
})

var order = @2
var files = {}

if (order[0])
  files[order[0]] = `@input(0)`
if (order[1])
  files[order[1]] = `@input(1)`
if (order[2])
  files[order[2]] = `@input(2)`
if (order[3])
  files[order[3]] = `@input(3)`
if (order[4])
  files[order[4]] = `@input(4)`
if (order[5])
  files[order[5]] = `@input(5)`
if (order[6])
  files[order[6]] = `@input(6)`
if (order[7])
  files[order[7]] = `@input(7)`

if (order[8])
  files[order[8]] = `@input(8)`
if (order[9])
  files[order[9]] = `@input(9)`


chan.join()
.receive("ok", (e) => {
    chan.push("lia", {event_id: "@1", message: {start: "CodeRunner", settings: null}})
    .receive("ok", (e) => {
        chan.push("lia", {event_id: "@1", message: {files: files}})
        .receive("ok", (e) => {
            if(@0) console.debug(e.message)
            chan.push("lia", {event_id: "@1", message: {compile: @3, order: order}})
            .receive("ok", (e) => {
                if(@0) console.debug(e.message)
                chan.push("lia", {event_id: "@1", message: {execute: @4}})
                .receive("ok", (e) => {})
                .receive("error", (e) => {
                    console.err("could not start application => ", e)
                    chan.push("lia", {event_id: "@1", message: {stop: ""}})
                    send.lia("LIA: stop")
                })
            })
            .receive("error", (e) => {
                send.lia(e.message, e.details, false)
                chan.push("lia", {event_id: "@1", message: {stop: ""}})
                send.lia("LIA: stop")
            })
        })
        .receive("error", (e) => {
            lia.error("could not setup files => ", e)
            chan.push("lia", {event_id: "@1", message: {stop: ""}})
            send.lia("LIA: stop")
        })
    })
    .receive("error", (e) => {
        lia.error("could not start service => ", e)
        chan.push("lia", {event_id: "@1", message: {stop: ""}})
        send.lia("LIA: stop")
    })
})
.receive("error", (e) => { lia.error("channel join => ", e); });


send.handle("input", (e) => {
    chan.push("lia", {event_id: "@1", message: {input: e}})
})
send.handle("stop",  (e) => {
    chan.push("lia", {event_id: "@1", message: {stop: ""}})
});


"LIA: wait"
</script>


@end
```
