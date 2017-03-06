### Creating a Simple Template
Creating a template is as easy as creating a normal Word document (`.docx`). Yet it could be confusing to people who haven't used the [Mail Merge](https://support.office.com/en-us/article/Use-mail-merge-to-send-bulk-email-messages-0f123521-20ce-4aa8-8b62-ac211dedefa4) feature in Microsoft Word. The steps are as follows:

- Create a new word document

![Step 1](/misc/step_1.png)

- Create your template

![Step 2](/misc/step_2.png)

- Add mail merge fields

- Click the `Insert` tab on the ribbon

![Step 3.1](/misc/step_3_1.png)

- Click the `Quick Parts` dropdown and select `Field...`

![Step 3.2](/misc/step_3_2.png)

- On the dialog, scroll down and select `MergeField`

![Step 3.3a](/misc/step_3_3_a.png)

 - Select `Field Codes`

![Step 3.3b](/misc/step_3_3_b.png)

![Step 4](/misc/step_4.png)

- In the `Field codes` input box, enter your variable in front of the `MERGEFIELD`. Notice the space between the `MERGEFIELD` and the variable

![Step 5](/misc/step_5.png)

- You should then have something like this:

![Step 6](/misc/step_6.png)

- A complete template might look like this:

![Step 7](/misc/step_7.png)

NOTE: When adding variables, those that display a value are preceded with an equals sign `=`. Those that just perform logics, such as loops and conditionals, do not need a preceding equals sign.
