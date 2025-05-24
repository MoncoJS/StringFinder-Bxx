import org.junit.runner.RunWith;
import org.junit.runners.Suite;
import org.junit.runners.Suite.SuiteClasses;

@RunWith(Suite.class)
@SuiteClasses({ TestCorrectAllLonger.class, TestCorrectAllShorter.class, TestCorrectSomeLonger.class,
		TestCorrectSomeShorter.class, TestExactlyCorrect.class })
public class AllTests {

}
