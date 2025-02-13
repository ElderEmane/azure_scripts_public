Because of limitations of azure function app all functions for working tags needed to be outside and then loaded as a module inside foreachobject.

Stopping and starting functions are called dynamically based on operation_hours tag.
operation_hours possibility:
24/7 - available all the time
adhoc - starting and stopping action happens every day inclusing weekend
adhoc_24/5 - starting and stopping action happens Monday - Friday
business_hours - starting and stopping action happens Monday - Friday 6AM - 06PM

to tags adhoc and adhoc_24/5 you should use autostarttime and autostoptime tags.
Tag can handle value in military clock except ':' i.e. 0600 is 6AM, 2000 is 8PM