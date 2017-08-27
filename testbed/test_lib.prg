procedure select_tests
   assert select() = 1
   assert select(0) = 1
   assert select(1) = 32767
   assert select(2) = 0
   assert select('test') = 0
ENDPROC

procedure chr_tests
   assert asc(chr(0)) = 0
endproc

procedure set_tests
   assert set('compatible') = 'OFF'
   assert set('compatible', 1) = 'PROMPT'
ENDPROC

procedure used_tests
   assert used('test') = .f.
endproc

procedure date_tests
   local somedate
   somedate = {^2017-6-30}
   assert somedate == Date(2017, 6, 30)
   assert dow(somedate) == 6
   assert cdow(somedate) == 'Friday'
   assert month(somedate) == 6
   assert cmonth(somedate) == 'June'
   assert len(time()) == 8
   assert len(time(1)) == 11
   assert dtot(somedate) == Datetime(2017, 6, 30, 0)
   assert gomonth(somedate, -4) = date(2017, 2, 28)
endproc

procedure math_tests
   assert round(pi(), 2) == 3.14
   assert abs(tan(dtor(45)) - 1) < 0.001
   assert abs(sin(dtor(90)) - 1) < 0.001
   assert abs(cos(dtor(90)) - 0) < 0.001
   assert abs(cos(dtor(45)) - sqrt(2)/2) < 0.001
   assert 0 < rand() and rand() < 1

   local stringval
   stringval = '1e5'
   assert val(stringval) = 100000
endproc

procedure string_tests
   cString = "AAA  aaa, BBB bbb, CCC ccc."
   assert GetWordCount(cString) == 6
   assert GetWordCount(cString, ",") = 3
   ASSERT GetWordCount(cString, ".") == 1
   assert GetWordNUM(cString, 2) == 'aaa,'
   assert GetWordNum(cString, 2, ",") = ' BBB bbb'
   ASSERT GETWORDNUM(cString, 2, ".") == ''
   assert like('Ab*t.???', 'About.txt')
   assert not like('Ab*t.???', 'about.txt')
   assert not isalpha('')
   assert isalpha('a123')
   assert not isalpha('1abc')
   assert not islower('')
   assert islower('test')
   assert not islower('Test')
   assert not isdigit('')
   assert isdigit('1abc')
   assert not isdigit('a123')
   assert not ISUPPER('')
   assert ISUPPER('Test')
   assert not ISUPPER('test')
   assert isblank('')
   assert not isblank('test')
   assert isblank({ / / })
   assert strextract('This {{is}} a {{template}}', '{{', '}}') == 'is'
   assert strextract('This {{is}} a {{template}}', '{{', '}}', 2) == 'template'
   assert strextract('This {{is}} a {{template}}', '{{is}}') ==  ' a {{template}}'
   assert strextract('This {{is}} a {{template}}', '{{IS}}', '', 1, 1) ==  ' a {{template}}'
ENDPROC

procedure path_tests
   assert HOME() == curdir()
   handle = fcreate('test_lib_file')
   fclose(handle)
   assert not isblank(locfile('test_lib_file'))
   CD ..
   assert HOME() != curdir()
   assert not isblank(locfile('test_lib_file'))
   delete file ADDBS(HOME()) + 'test_lib_file'
endproc

procedure _add_db_record(seed)
   LOCAL fake, fake_name, fake_st, fake_quantity, fake_received
   fake = pythonfunctioncall('faker', 'Faker', createobject('pythontuple'))
   fake.callmethod('seed', createobject('pythontuple', seed))
   fake_name = fake.callmethod('name', createobject('pythontuple'))
   fake_st = fake.callmethod('state_abbr', createobject('pythontuple'))
   fake_quantity = fake.callmethod('random_int', createobject('pythontuple', 0, 100))
   fake_received = fake.callmethod('boolean', createobject('pythontuple'))
   insert into report values (fake_name, fake_st, fake_quantity, fake_received)
endproc

procedure database_tests
   SET SAFETY OFF
   SET ASSERTS ON
   try
      CREATE TABLE REPORT FREE (NAME C(50), ST C(2), QUANTITY N(5, 0), RECEIVED L(1))
      ASSERT FILE('report.dbf')
      ASSERT USED('report')
      try
         USE report in 0 shared
         assert .f.
      catch to oerr
         ?oerr.message
         assert oerr.message == 'File is in use.'
      endtry
      _add_db_record(0)
      _add_db_record(1)
      _add_db_record(2)
      _add_db_record(3)
      ASSERT FCOUNT() == 4
      ALTER TABLE REPORT ADD COLUMN AGE N(3, 0)
      ASSERT FCOUNT() == 5
      assert field(2) == 'st'
      assert not found()
      go top
      assert alltrim(name) == 'Norma Fisher' MESSAGE alltrim(name) + ' should be Norma Fisher'
      assert recno() == 1
      go bott
      assert alltrim(name) == 'Joshua Wood' MESSAGE alltrim(name) + ' should be Joshua Wood'
      assert recno() == 4
      goto 1
      locate for st == 'ID'
      assert alltrim(name) == 'Norma Fisher' MESSAGE alltrim(name) + ' should be Norma Fisher'
      assert found()
      continue
      assert alltrim(name) == 'Ryan Gallagher' MESSAGE alltrim(name) + ' should be Ryan Gallagher'
      continue
      assert EOF()
      assert recno() == reccount() + 1
      assert not found()
      count for quantity > 60 to countval
      assert countval = 2
      assert eof()
      sum sqrt(quantity + 205) for quantity > 50 while quantity != 63 to sumval
      assert sumval == 0
      go top
      sum sqrt(quantity + 205) for quantity > 50 while quantity != 63 to sumval
      assert sumval == 17 + 16
      index on st tag st
      seek 'CA'
      assert alltrim(st) == 'CA'
      go top
      DELETE REST FOR QUANTITY > 60
      PACK
      go top
      assert reccount() == 2
      REPLACE REPORT.NAME WITH 'N/A'
      assert alltrim(name) == 'N/A'
      REPLACE ALL NAME WITH 'Not Available'
      assert recno() == reccount() + 1
      GO BOTT
      assert alltrim(name) == 'Not Available'
      ZAP
      ASSERT RECCOUNT() == 0
      copy structure to report2
      USE report2 in 0 shared
      assert alias() == 'report'
      SELECT report2
      assert alias() == 'report2'
      ASSERT FCOUNT() == 5
      ALTER TABLE REPORT2 DROP COLUMN ST
      ASSERT FCOUNT() == 4
      use
      DELETE FILE REPORT2.DBF
   catch to err
      ?err.message
      browse
      throw
   finally
      DELETE FILE REPORT.DBF
   endtry
   sqlconn = sqlconnect('testodbc')
   assert sqlconn > 0
   sqldisconnect(sqlconn)
endproc
