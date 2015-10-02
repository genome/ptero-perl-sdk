### Background

This is an example of building a **Workflow** that consists of a single **Task** using the perl SDK.
**Task**s represent some work that you want to get done.
**Task**s can have inputs and produce outputs, but they don't have to, and in this example we neglect inputs and outputs.

**Task**s represent the work to be done, but it is the job of the **Method**s to describe how a **Task** should be completed.
A **Task** contains a list of **Methods** to try.
When the **Task** is executed, these **Method**s are attempted in order until one succeeds or they all fail.

### Example

We start out by creating a workflow, all we need to do is name it.


```perl
use Ptero::Builder::Workflow;
use Ptero::Builder::Detail::Workflow::Task;
use Ptero::Builder::Job;

my $workflow = Ptero::Builder::Workflow->new(name => "SomeWorkflow");
```


Since a **Task** represents work to be done, and not how the work should be done, it's easy to define.
In fact, it only requires a name.
To add a task to a workflow use the **->add_task** method.



```perl
my $task = Ptero::Builder::Detail::Workflow::Task->new(name => "SomeTask");
$workflow->add_task($task);
```


To add a **Method** to a task, you can use the **->add_method** method like below.



```perl
my $method = Ptero::Builder::Job->new(
    name => "SomeMethod",
    service_url => "http://some-job-service.example.com/v1",
    parameters => {
        commandLine => [
            'ptero-perl-subroutine-wrapper',
            '--package' => 'Some::Perl::Module',
            '--subroutine' => 'some_subroutine'
        ],
        environment => {PERL5LIB => '/path/to/some/perl/module'},
        user => 'some_user',
        workingDirectory => '/tmp',
    },
);
$task->add_method($method);
```


Finally, we just need to add links to the **Workflow** to indicate when we want the task to run.
In this case, we only have one task so it's a little silly but here's how its done:



```perl
$workflow->create_link(destination => $task);
$workflow->create_link(source => $task);
```


This workflow, built up programmatically using the Perl SDK is equivalent to this JSON representation:



```json
{
   "links" : [
      {
         "destination" : "SomeTask",
         "source" : "input connector"
      },
      {
         "destination" : "output connector",
         "source" : "SomeTask"
      }
   ],
   "tasks" : {
      "SomeTask" : {
         "methods" : [
            {
               "name" : "SomeMethod",
               "parameters" : {
                  "commandLine" : [
                     "ptero-perl-subroutine-wrapper",
                     "--package",
                     "Some::Perl::Module",
                     "--subroutine",
                     "some_subroutine"
                  ],
                  "environment" : {
                     "PERL5LIB" : "/path/to/some/perl/module"
                  },
                  "user" : "some_user",
                  "workingDirectory" : "/tmp"
               },
               "service" : "job",
               "serviceUrl" : "http://some-job-service.example.com/v1"
            }
         ]
      }
   }
}
```

