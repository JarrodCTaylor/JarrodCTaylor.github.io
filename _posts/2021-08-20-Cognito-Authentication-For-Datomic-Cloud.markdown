---
layout: post
title: Cognito Authentication For Datomic Cloud
tags: clojure datomic
category: posts
---

# Using Cognito Authentication with Datomic Cloud

## Preamble

Apart from rhythm and blues you might be hard pressed to find an example of something
more commonly found together than web requests and authentication. While what follows
is but one of the almost countless ways to configure routes and authentication in a Datomic
Cloud application, it will provide a respectable starting place.

We will assume you have completed the [Datomic Cloud setup](https://www.youtube.com/watch?v=DsThGK5bZCQ). As you contemplate
the possibilities of the blank canvas that is a new cloud stack, inspiration strikes!
Now with a clear picture in mind of the next billion-dollar startup, you are ready
to begin creating new users as soon as possible. The lack of user authentication is
the only thing standing in your way. Read on to see *one way* you might go about
conquering that challenge.

## The Starting Place

The API Gateway which is automatically created as part of the setup process
includes a `$default` route. This is a catch-all and simply proxies every
request to the deployed ion. Our budding new startup is going to need
publicly accessible routes for prospective users to ask questions and
create accounts. It will also need authenticated routes so the users can...
well, let's keep this part quiet until the multi-billion dollar IPO. For
now, it is good enough to say that it will need authenticated routes.

## The Ion App

The [Ion Cognito Exemplar](https://github.com/JarrodCTaylor/ion-cognito-exemplar) app consists of a reitit router that has
two endpoints;; one open to the public and one that requires authentication.
The authed endpoint `/say-hello` uses the identity contained in a Cognito
token to say hello to the user making the request by name.

### Deploy the Example

 * Clone the repository: `git clone git@github.com:JarrodCTaylor/ion-cognito-exemplar.git`

 * Update `:app-name` in `resources/datomic/ion-config.edn` with your system name

 * [Push and deploy](https://docs.datomic.com/cloud/ions/ions-reference.html#push).

## AWS Setup

A terraform script is included in the Ion Cognito Exemplar project in the scripts directory.

This script creates the following resources:
  * A Cognito user pool
    * An app client in the user pool. This is the bridge between the AWS API Gateway and Cognito
    * A new test user inside the user pool with a verified password
  * API Gateway Routes (Added to the Ion API Gateway created by Datomic Cloud)
    * `/api/v1/public/{proxy+}`
    * A gateway Authorizer using the newly created user pool and client app
    * `/api/v1/authed/{proxy+}`
    * A catch all OPTIONS route. This is needed for CORS requests from a browser. While outside the scope of this example it is almost always needed sooner than later.

The public and authed routes are both ANY methods and proxy through to the load balancer
which sits in front of the deployed application. The authed route additionally includes
the authorizer which expects to find a token in the Authorization header of the request.
Cognito is called to verify the token. If the token is valid the request is proxied
through to the load balancer. If not, it is rejected with a 403 response.

In the scripts directory is a file named `log-commands.sh`. Run this script passing the
name of the compute stack as an argument. If you followed along with the [Datomic Cloud setup](https://www.youtube.com/watch?v=DsThGK5bZCQ)
the compute stack should have a name resembling `<YOUR-STACK-NAME>-Compute-<RANDOM-ID>`
and can be found in the `Stack Name` column of CloudFormation.

In the scripts directory call the script:

```shell
./log-commands.sh <YOUR-STACK-NAME>-Compute-<RANDOM-ID>
```

This script is a convenience to eliminate needing to lookup values in the CloudFormation outputs tab.
It retrieves the values for `IonApiGatewayEndpoint`, `HttpDirectApiIntegration` and
`HttpDirectApiGateway` then outputs two things:
* A curl command to call the /ping endpoint to ensure a functioning deployment
* A terraform apply command with the needed variables

If all has gone well until this point the curl command will receive a successful response of:
`{"message":"Pong'ing back"}`.

Now, assuming terraform is installed, in the scripts directory run `terraform init`
followed by the command that was outputted by the script.

When that completes successfully we are ready for the final testing step.

## Testing it Out

The `test-endpoints.sh` script does the following:
* Read the outputs from terraform to retrieve values for `apiUrl` `userPool` and `userPoolClient`
* Make an unauthenticated call to the ping route and print the results (expected {"message":"Pong'ing back"})
* Retrieve an authentication token for the test user
* Make a valid authenticated call to the `say-hello` endpoint and print the results (expected {"message":"Hello, exemplaruser"})
* Make a invalid authenticated call to the `say-hello` endpoint and print the results (expected {"message":"Unauthorized"})

If you receive the expected responses Congratulations! The tech startup world is now yours to disrupt.
