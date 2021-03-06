---
layout: post
title: Breaking your promises in Javascript
---

I love that modern Javascript supports promises, and the await/async syntax.
But native promises can't (currently) be cancelled. This is a great shame, as
it can encourage developers to write unresponsive user interfaces.

For example, suppose we're building a dashboard that is populated with data from
an API. Each time the user picks a new date on the dashboard, we want to load in
 the relevant data. It's tempting to code this such that the request fires and
 then our UI re-renders with the latest data. In React, we might write this as
 shown below. Note that the `datePickerEnabled` state is used to disable the
 date picker whilst there's an API request in flight.

```jsx
import React, {useEffect, useState} from "react";
import axios from "axios"; // for HTTP requests

function Dashboard() {
    // Initialise state for storing the current date and the current
    // counter value
    const [date, setDate] = useState(new Date);
    const [value, setValue] = useState("-");

    // Initialise state for controlling whether or not to enable
    // the date picker
    const [datePickerEnabled, setDatePickerEnabled] = useState(true);

    // Prepare a function for loading the counter value by hitting
    // an API
    const loadValue = async (date) => {
        const newValue = await axios.get("/counter", {date});
        setValue(newValue);
    };

    // Schedule loading of the counter value for when React mounts
    // this component
    useEffect(() => { loadValue(date) }, []);

    // Prepare a function for updating the date and loading the
    // relevant counter value
    const onDateChange = async (newDate) => {
        setDate(newDate);
        setDatePickerEnabled(false);
        await loadValue(newDate);
        setDatePickerEnabled(true);
    };

    // Render a date picker and the counter
    return (
        <div>
            <DateRangePicker
              date={date}
              onChange={onDateChange}
              enabled={datePickerEnabled}
            />

            <Counter value={value}/>
        </div>
    )
}
```

This code works but it provides a fairly unresponsive user experience: a user
has to wait for the API request to finish and the counter value to update before
they can pick a new date. This can be frustrating if you pick the wrong date or
if the API is slow to respond.

We could opt not to disable the date picker when there's an API request in
flight, but that can lead to inconsistent results. Our API requests are not
guaranteed to return in the order that we send them (e.g., if an earlier request
suffers a delay).

Instead, my preferred solution nowadays is to keep the UI responsive, but to
cancel the consequences of earlier promises. Here's a version of the earlier
React component that breaks any previous promises:

```jsx
import React, {useEffect, useState} from "react";
import axios from "axios";

function Dashboard() {
    // Initialise state for storing the current date and the current
    // counter value
    const [date, setDate] = useState(new Date);
    const [value, setValue] = useState("-");

    // Initialise state that stores a function for cancelling any
    // previous promise. Note: functions stored in React's useState
    // must be wrapped (in a function)
    const [cancelPreviousPromise, setCancelPreviousPromise] =
      useState(() => () => {});

    // Prepare a function for loading the counter value by hitting
    // an API
    const loadValue = async (date) => {
        const [cancellablePromise, cancel] =
          cancellable(axios.get("/counter", {date}));

        // Cancel the consequences of any previous promise
        cancelPreviousPromise();

        // Allow subsequent promises to be able to cancel updates
        // Note: functions stored in React's useState must
        // be wrapped (in a function)
        setCancelPreviousPromise(() => cancel);

        try {
            // Wait for the new data to load
            const newValue = await cancellablePromise;

            // Store the new value ready for display in the counter
            setValue(newValue);

        } catch (error) {
            // Ignore any errors from cancelled promises
            if (error instanceof CancelledPromiseError) return;

            // ... other error handling omitted
        }
    };

    // Schedule loading of the counter value for when React mounts
    // this component
    useEffect(() => { loadValue(date) }, []);

    // Prepare a function for updating the date and loading the
    // relevant counter value
    const onDateChange = async (newDate) => {
        setDate(newDate);
        await loadValue(newDate);
    };

    // Render a date picker and the counter
    return (
        <div>
            <DateRangePicker
              date={date}
              onChange={onDateChange}
              enabled
            />

            <Counter value={value}/>
        </div>
    )
}
```

The key here is to store a function (in the `cancelPreviousPromise`) state
that can be used to cancel the consequences of an earlier promises. If the user
selects a date whilst there's already a request in flight, the code after the
`await` doesn't run and a `CancelledPromiseError` is thrown instead. This keeps
the UI responsive and consistent!

Here's the implementation of `cancellable`:

```javascript
const cancellable = (original) => {
    let cancel = () => {};

    const cancellation = new Promise(
        (resolve, reject) =>
          cancel = () => reject(new CancelledPromiseError(original))
    );

    const wrapped = Promise.race([original, cancellation]);

    return [wrapped, cancel];
};

class CancelledPromiseError extends Error {
    constructor(promise) {
        super("Promise was cancelled");
        this.name = 'CancelledPromiseError';
        this.promise = promise;
    }
}
```

`cancellable` races our original promise with a further promise that only
completes (rejects) if the `cancel` function returned as the second argument
from `cancellable` is called. Thanks to [Pho3nixHun](https://stackoverflow.com/a/49865441/9902857)
for this implementation!
