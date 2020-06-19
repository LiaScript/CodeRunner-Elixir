<!--
author:   André Dietrich

email:    LiaScript@github.io

version:  0.0.1

language: en

narrator: US English Female

comment:  This template allows to run C, C++, C# code on a server, while
          communication with LiaScript-courses.

script:   https://cdn.jsdelivr.net/npm/phoenix-js@1.0.3/dist/glob/main.js

@LIA.eval: @LIA.eval_("@uid",@0,@1,@2,@3)

@LIA.eval_
<script>
var ROOT_SOCKET = 'wss://liarunner.herokuapp.com/socket'; // default path is /socket
var socket = new Socket(ROOT_SOCKET);
socket.connect(); // connect
var chan = socket.channel("lia:asfdasd");

chan.on("service", (e) => {
  if (e.message.stderr)
    console.error(e.message.stderr)
  else if (e.message.stdout) {
    if (!e.message.stdout.startsWith("Warning: cannot switch "))
      console.log(e.message.stdout)
  }
  else if (e.message.exit) {
    console.debug(e.message.exit)
    send.lia("LIA: stop")
  }
})

chan.join()
.receive("ok", (e) => {
    chan.push("lia", {event_id: @0, message: {start: "CodeRunner", settings: null}})
    .receive("ok", (e) => {
        chan.push("lia", {event_id: @0, message: {files: @1}})
        .receive("ok", (e) => {
            console.debug(e.message)
            chan.push("lia", {event_id: @0, message: {compile: "@3", order: [@2]}})
            .receive("ok", (e) => {
                console.debug(e.message)
                chan.push("lia", {event_id: @0, message: {execute: "@4"}})
                .receive("ok", (e) => {
                    //console.debug(e.message)
                    send.lia("LIA: terminal")
                })
                .receive("error", (e) => {
                    console.err("could not start application => ", e)
                    send.lia("LIA: stop")
                })
            })
            .receive("error", (e) => {
                send.lia(e.message, e.details, false)
                send.lia("LIA: stop")
            })
        })
        .receive("error", (e) => {
            lia.error("could not setup files => ", e)
            send.lia("LIA: stop")
        })
    })
    .receive("error", (e) => {
        lia.error("could not start service => ", e)
        send.lia("LIA: stop")
    })
})
.receive("error", (e) => { lia.error("channel join => ", e); });


send.handle("input", (e) => {
    chan.push("lia", {event_id: @0, message: {input: e}})
})
send.handle("stop",  (e) => {
    chan.push("lia", {event_id: @0, message: {stop: ""}})
});


"LIA: wait"
</script>


@end



@LIA.eval2
<script>
var ROOT_SOCKET = 'wss://liarunner.herokuapp.com/socket'; // default path is /socket
var socket = new Socket(ROOT_SOCKET);
socket.connect(); // connect
var chan = socket.channel("lia:asfdasd");

chan.on("service", (e) => {
  if (e.message.stderr)
    console.error(e.message.stderr)
  else if (e.message.stdout) {
    if (!e.message.stdout.startsWith("Warning: cannot switch "))
      console.log(e.message.stdout)
  }
  else if (e.message.exit) {
    console.debug(e.message.exit)
    send.lia("LIA: stop")
  }
})

chan.join()
.receive("ok", (e) => {
    chan.push("lia", {event_id: "@0", message: {start: "CodeRunner", settings: null}})
    .receive("ok", (e) => {
        chan.push("lia", {event_id: "@0", message: {files: {"Program.cs": `@input`, "ClassExample.cs": `@input(1)`, "LiascriptMeetsCsharp.csproj": `@input(2)`}}})
        .receive("ok", (e) => {
            console.debug(e.message)
            chan.push("lia", {event_id: "@0", message: {compile: "dotnet build", order: []}})
            .receive("ok", (e) => {
                console.debug(e.message)
                chan.push("lia", {event_id: "@0", message: {execute: "dotnet run"}})
                .receive("ok", (e) => {
                    //console.debug(e.message)
                    send.lia("LIA: terminal")
                })
                .receive("error", (e) => {
                    console.err("could not start application => ", e)
                    send.lia("LIA: stop")
                })
            })
            .receive("error", (e) => {
                send.lia(e.message, e.details, false)
                send.lia("LIA: stop")
            })
        })
        .receive("error", (e) => {
            lia.error("could not setup files => ", e)
            send.lia("LIA: stop")
        })
    })
    .receive("error", (e) => {
        lia.error("could not start service => ", e)
        send.lia("LIA: stop")
    })
})
.receive("error", (e) => { lia.error("channel join => ", e); });


send.handle("input", (e) => {
    chan.push("lia", {event_id: "@0", message: {input: e}})
})
send.handle("stop",  (e) => {
    chan.push("lia", {event_id: "@0", message: {stop: ""}})
});


"LIA: wait"
</script>


@end
-->

# CodeRunner

todo

## Examples


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
@LIA.eval({'main.c':`@input`}, "main.c", gcc -Wall main.c -o a.out, ./a.out)


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
@LIA.eval({'main.cpp':`@input`}, "main.cpp", g++ main.cpp -o a.out, ./a.out)

### C#


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
@LIA.eval({'main.cs':`@input`},"main.cs",mono main.cs,mono main.exe)


## C# 2



```csharp           Program.cs
using System;

namespace LiascriptMeetsCsharp
{
    class Program
    {
        private const string Message = "I ❤ LiaScript! ";

        static void Main(string[] args)
        {
            ClassExample greeter = new ClassExample(5, Message);
            Console.WriteLine(greeter);
        }
    }
}
```
```csharp           -ClassExample.cs
using System;
using System.Diagnostics;
using System.Text;

namespace LiascriptMeetsCsharp
{
    class ClassExample
    {
        private int greetingCounts = 0;
        private string greetings = "Hello";

        public ClassExample(int GreetingCounts,
                     string message)
        {
            this.greetingCounts = GreetingCounts;
            this.greetings = message;
        }

        public int GreetingCounts
        {
            get { return greetingCounts; }
            set {
                if (value > 100)
                    throw new ArgumentOutOfRangeException(
                        $"{nameof(value)} must be between 0 and 100.");
                greetingCounts = value;
            }
       }


        public string Greetings
        {
            get { return greetings; }
            set {greetings = value;}
        }

        public override string ToString() => new StringBuilder(greetings.Length * greetingCounts).Insert(0, greetings, greetingCounts).ToString();
    }
}
```
``` xml           -LiaScriptMeetsScharp.csproj
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>netcoreapp3.1</TargetFramework>
  </PropertyGroup>

</Project>
```
@LIA.eval2(@uid)

### Python2


```c
for i in range(10):
  print "Hallo Welt", i
```
@LIA.eval({'main.py':`@input`}, "main.py", python -m compileall ., python main.pyc)


### Python3


```c
for i in range(10):
  print("Hallo Welt", i)
```
@LIA.eval({'main.py':`@input`}, "main.py", python3 -m compileall ., python3 main.pyc)



# Deploying to Heroku

1. Install the Heroku CLI ([Heroku-CLI](https://devcenter.heroku.com/articles/heroku-cli))
2. Create a new Heroku project
    1. Login to Heroku: `heroku login` (Don't use sudo or it will not work!)
    2. Create the project: `heroku create [app_name]`
3. Login to Heroku container: `sudo heroku container:login` (It's important that you have docker installed before executing this command.)
4. Build the docker container and upload it to heroku: `sudo heroku container:push web -a app_name`
5. Release the docker container: `sudo docker container:release web -a app_name`

Your project url is now `app_name.herokuapp.com`. (Or the auto-generated one when you haven't supplied an app name.)
