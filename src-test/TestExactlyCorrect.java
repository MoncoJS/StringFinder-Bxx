import static org.junit.Assert.*;

import org.junit.Test;

public class TestExactlyCorrect {

	@Test
	public void test() {
		StringFinder a = new StringFinder(new Secret("ABCDEFG"));
		
		// correct string
		assertEquals(0,a.getGoal().evaluate("ABCDEFG"));
	}

}
